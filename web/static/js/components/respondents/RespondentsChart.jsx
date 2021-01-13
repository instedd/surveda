import React, { PureComponent } from 'react'
import { referenceStrokeColorClasses } from '../../referenceColors'
import * as d3 from 'd3'

class RespondentsChart extends PureComponent {
  static propTypes = {
    cumulativePercentages: React.PropTypes.object.isRequired
  }

  componentDidMount() {
    this.width = this.refs.main.offsetWidth
    this.height = this.width / 2
    this.chartMargin = { top: 0, bottom: 20, left: 0, right: 0 }
    this.chartWidth = this.width - this.chartMargin.left - this.chartMargin.right
    this.chartHeight = this.height - this.chartMargin.top - this.chartMargin.bottom
    this.renderD3()
  }

  componentDidUpdate() {
    this.renderD3()
  }

  buildPaths(container, total) {
    let paths = []
    for (let i = 0; i < total; ++i) {
      paths.push(container.append('path').attr('class', 'line'))
    }

    return paths
  }

  renderD3() {
    const { cumulativePercentages } = this.props
    const svg = d3.select(this.refs.svg)
    const container = d3.select(this.refs.container)
    const backgroundPath = d3.select(this.refs.backgroundPath)
    const yaxisContainer = d3.select(this.refs.yaxis)
    const xaxisContainer = d3.select(this.refs.xaxis)
      .attr('transform', 'translate(0,' + (this.chartHeight) + ')')

    const xScale = d3.scaleTime()
    const yScale = d3.scaleLinear().domain([0, 100])

    // Set size
    xScale.range([0, this.chartWidth])
    yScale.range([this.chartHeight, 0])

    // Set data
    let initialDate, lastDate
    const totalQuestionnaires = Object.keys(cumulativePercentages).length

    if (!cumulativePercentages || totalQuestionnaires < 1) {
      initialDate = new Date()
      lastDate = new Date()
      lastDate.setDate(lastDate.getDate() + 90)
    } else {
      // Uses random one because all questionnaires have the same range of dates.
      const randomQuestionnaireId = Object.keys(cumulativePercentages)[0]
      const randomQuestionnaireByDate = cumulativePercentages[randomQuestionnaireId]
      initialDate = new Date(Date.parse(randomQuestionnaireByDate[0].date))
      const nextThreeMonths = new Date(Date.parse(randomQuestionnaireByDate[0].date))
      nextThreeMonths.setDate(nextThreeMonths.getDate() + 90)
      lastDate = new Date(Math.max(Date.parse(randomQuestionnaireByDate[randomQuestionnaireByDate.length - 1].date), nextThreeMonths))
    }

    const formatDate = date => new Date(Date.parse(date))
    const datas = Object.entries(cumulativePercentages).map((entry) => {
      let completedPercentagesByDate = entry[1]
      return completedPercentagesByDate.map(v => (
        { date: formatDate(v.date), percent: Number(v.percent) }
      ))
    })

    xScale.domain([initialDate, lastDate])

    const xaxis = d3.axisBottom()
      .scale(xScale)
      .ticks(3)

    const yaxis = d3.axisRight()
      .scale(yScale)
      .tickSize(this.width)
      .ticks(4)

    xaxisContainer.call(xaxis
        .ticks(3)
        .tickFormat(d3.timeFormat('%b')))
        .selectAll('text')
        .attr('dy', 7)
        .attr('x', 10)

    yaxisContainer.call(yaxis)
        .selectAll('text')
          .attr('x', 0)
          .attr('dy', 16)

    const line = d3.line()
      .x(d => xScale(d.date))
      .y(d => yScale(d.percent))

    const paths = this.buildPaths(container, totalQuestionnaires)
    let referenceClasses = referenceStrokeColorClasses(totalQuestionnaires)
    datas.forEach((data, index) => {
      paths[index].datum(data)
          .attr('class', `line respondentsData ${referenceClasses[index]}`)
          .attr('d', line)
    })

    const backgroundData = [{date: initialDate, percent: 0}, {date: lastDate, percent: 100}]
    backgroundPath.datum(backgroundData)
      .attr('class', 'line backgroundData')
      .style('stroke-dasharray', '2,2')
      .attr('d', line)

    svg
      .attr('width', this.width)
      .attr('height', this.height)
  }

  render() {
    return (
      <div ref='main'>
        <svg ref='svg'>
          <g ref='container'>
            <g className='y axis' ref='yaxis' />
            <g className='x axis' ref='xaxis' />
            <path className='line' ref='backgroundPath' />
          </g>
        </svg>
      </div>
    )
  }
}

export default RespondentsChart
