import React, { Component } from 'react'
import rd3 from 'react-d3-library'
const RD3Component = rd3.Component

class RespondentsChart extends Component {
  constructor(props) {
    super(props)
    this.state = { d3: '' }
  }

  componentDidMount() {
    const width = this.refs.container.offsetWidth
    this.setState({width: width, height: (width * 1/2)})
  }

  data(completedByDate, x, y) {
    const formatDate = function(date) { return new Date(Date.parse(date)) }
    const data = completedByDate.map((d) => { return { date: formatDate(d.date), count: Number(d.count) } })
    x.domain(d3.extent(data, function(d) { return d.date }))
    return data
  }

  setSize(x, y, margin, width, height) {
    const chartWidth = width
    const chartHeight = height - margin.bottom
    x.range([0, chartWidth])
    y.range([chartHeight, 0])
  }

  init(svg, margin, width, height) {
    const container = svg.append('g')
    const YAxis = container.append('g')
                          .attr('class', 'y axis')
    const XAxis = container.append('g')
                          .attr('class', 'x axis')
                          .attr('transform', 'translate(0,' + (height) + ')')
    const path = container.append('path')
                          .attr('class', 'line')
    return({YAxis: YAxis, XAxis: XAxis, path: path})
  }

  renderD3() {
    const { width, height, margin } = this.state
    if (!width) {
      return null
    }

    const { completedByDate } = this.props
    const node = document.createElement('div')
    const svg = d3.select(node).append('svg')

    const x = d3.time.scale()
    const y = d3.scale.linear().domain([0, 100])
    const yaxis = d3.svg.axis()
                        .scale(y)
                        .tickSize(width)
                        .ticks(4)
                        .orient('right')
    const xaxis = d3.svg.axis()
                        .scale(x)
                        .ticks(4)
    const line = d3.svg.line()
                        .x(function(d) { return x(d.date) })
                        .y(function(d) { return y(d.count) })

    const margin = {top: 0, left: 0, right: 0, bottom: 20}

    const { YAxis, XAxis, path } = this.init(svg, margin, width, height)
    this.setSize(x, y, margin, width, height)
    const data = this.data(completedByDate, x, y)

    svg.attr('width', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)

    YAxis.call(yaxis)
        .selectAll('text')
          .attr('x', 0)
          .attr('dy', 16)

    XAxis.call(xaxis)
        .selectAll('text')
        .attr('dy', 7)

    path.datum(data)
        .attr('class', 'line')
        .attr('d', line)

    return (<RD3Component data={node} />)
  }

  render() {
    return (
      <div ref='container'>
        {this.renderD3()}
      </div>
    )
  }
}

export default RespondentsChart
