import React, { Component } from 'react'
import rd3 from 'react-d3-library'
import { referenceColorsFor } from '../../referenceColors'
const RD3Component = rd3.Component

class RespondentsChart extends Component {
  constructor(props) {
    super(props)
    this.state = { d3: '' }
  }

  static propTypes = {
    cumulativePercentages: React.PropTypes.object.isRequired
  }

  componentDidMount() {
    this.width = this.refs.container.offsetWidth
    this.height = this.width * (1 / 2)
    this.chartMargin = {top: 0, bottom: 20, left: 0, right: 0}
    this.chartWidth = this.width - this.chartMargin.left - this.chartMargin.right
    this.chartHeight = this.height - this.chartMargin.top - this.chartMargin.bottom
    this.renderD3()
  }

  componentWillReceiveProps(nextProps) {
    this.setData(nextProps.cumulativePercentages)
  }

  setData(cumulativePercentages) {
    let initialDate
    let nextThreeMonths
    let lastDate
    let totalQuestionnairesWithAnyCompletion = Object.keys(cumulativePercentages)
    if (!cumulativePercentages || totalQuestionnairesWithAnyCompletion < 1) {
      initialDate = new Date(Date.now())
      lastDate = new Date(Date.now())
      lastDate.setDate(lastDate.getDate() + 90)
    } else {
      // Uses random one because all questionnaires have the same range of dates.
      let randomQuestionnaireId = Object.keys(cumulativePercentages)[0]
      let randomQuestionnaireByDate = cumulativePercentages[randomQuestionnaireId]
      initialDate = new Date(Date.parse(randomQuestionnaireByDate[0].date))
      nextThreeMonths = new Date(Date.parse(randomQuestionnaireByDate[0].date))
      nextThreeMonths.setDate(nextThreeMonths.getDate() + 90)
      lastDate = new Date(Math.max(Date.parse(randomQuestionnaireByDate[randomQuestionnaireByDate.length - 1].date), nextThreeMonths))
    }
    const formatDate = function(date) { return new Date(Date.parse(date)) }
    this.datas = Object.entries(cumulativePercentages).map((entry) => {
      let completedPercentagesByDate = entry[1]
      return completedPercentagesByDate.map((v) => {
        return { date: formatDate(v.date), count: Number(v.percentage) }
      })
    });

    (this._x).domain([initialDate, lastDate])

    this.xaxis = d3.svg.axis()
                        .scale(this._x)
                        .ticks(3)

    const _x = this._x
    const _y = this._y
    this.line = d3.svg.line()
                        .x(function(d) { return _x(d.date) })
                        .y(function(d) { return _y(d.count) })

    this.backgroundData = [{date: initialDate, count: 0}, {date: lastDate, count: 100}]

    this.XAxis.call(this.xaxis
        .ticks(3)
        .tickFormat(d3.time.format('%b')))
        .selectAll('text')
        .attr('dy', 7)
        .attr('x', 10)

    this.datas.forEach((data, index) => {
      this.paths[index].datum(data)
          .attr('class', 'line respondentsData')
          .attr('d', this.line)
    })

    this.backgroundPath.datum(this.backgroundData)
        .attr('class', 'line backgroundData')
        .style('stroke-dasharray', '2,2')
        .attr('d', this.line)
  }

  setSize() {
    this._x.range([0, this.chartWidth])
    this._y.range([this.chartHeight, 0])
  }

  init(totalQuestionnaires) {
    this.container = this.svg.append('g')
    this.YAxis = this.container.append('g')
                          .attr('class', 'y axis')
    this.XAxis = this.container.append('g')
                          .attr('class', 'x axis')
                          .attr('transform', 'translate(0,' + (this.chartHeight) + ')')
    this.paths = []
    let referenceColors = referenceColorsFor(totalQuestionnaires)
    for (let i = 0; i < totalQuestionnaires; ++i) {
      this.paths.push(this.container.append('path')
                                    .attr('class', 'line')
                                    .style('stroke', referenceColors[i]))
    }

    this.backgroundPath = this.container.append('path')
                                    .attr('class', 'line')

    this._x = d3.time.scale()
    this._y = d3.scale.linear().domain([0, 100])

    this.yaxis = d3.svg.axis()
                        .scale(this._y)
                        .tickSize(this.width)
                        .ticks(4)
                        .orient('right')
    this.xaxis = d3.svg.axis()
                        .scale(this._x)

    const _x = this._x
    const _y = this._y
    this.line = d3.svg.line()
                        .x(function(d) { return _x(d.date) })
                        .y(function(d) { return _y(d.count) })
  }

  renderD3() {
    if (!this.width) {
      return
    }

    const { cumulativePercentages } = this.props
    const node = document.createElement('div')
    this.svg = d3.select(node).append('svg')

    let totalQuestionnaires = Object.keys(cumulativePercentages).length
    this.init(totalQuestionnaires)
    this.setSize()
    this.setData(cumulativePercentages)

    this.svg.attr('width', this.width)
        .attr('height', this.height)

    this.YAxis.call(this.yaxis)
        .selectAll('text')
          .attr('x', 0)
          .attr('dy', 16)

    this.XAxis.call(this.xaxis)
        .selectAll('text')
        .attr('dy', 7)

    this.setState({node: node})
  }

  render() {
    return (
      <div ref='container'>
        <RD3Component data={this.state.node} />
      </div>
    )
  }
}

export default RespondentsChart
