import React, { Component } from 'react'
import rd3 from 'react-d3-library'
const RD3Component = rd3.Component

class RespondentsChart extends Component {
  constructor(props) {
    super(props)
    this.state = { d3: '' }
  }

  componentDidMount() {
    this.width = this.refs.container.offsetWidth
    this.height = this.width * (1 / 2)
    this.chartMargin = {top: 0, bottom: 20, left: 0, right: 0}
    this.chartWidth = this.width - this.chartMargin.left - this.chartMargin.right
    this.chartHeight = this.height - this.chartMargin.top - this.chartMargin.bottom
  }

  setData(completedByDate) {
    const formatDate = function(date) { return new Date(Date.parse(date)) }
    this.data = completedByDate.map((d) => { return { date: formatDate(d.date), count: Number(d.count) } });
    (this._x).domain(d3.extent(this.data, function(d) { return d.date }))
  }

  setSize() {
    this._x.range([0, this.chartWidth])
    this._y.range([this.chartHeight, 0])
  }

  init() {
    this.container = this.svg.append('g')
    this.YAxis = this.container.append('g')
                          .attr('class', 'y axis')
    this.XAxis = this.container.append('g')
                          .attr('class', 'x axis')
                          .attr('transform', 'translate(0,' + (this.chartHeight) + ')')
    this.path = this.container.append('path')
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
                        .ticks(4)

    const _x = this._x
    const _y = this._y
    this.line = d3.svg.line()
                        .x(function(d) { return _x(d.date) })
                        .y(function(d) { return _y(d.count) })
  }

  renderD3() {
    if (!this.width) {
      return null
    }

    const { completedByDate } = this.props
    this.node = document.createElement('div')
    this.svg = d3.select(this.node).append('svg')

    this.init()
    this.setSize()
    this.setData(completedByDate)

    this.svg.attr('width', this.width)
        .attr('height', this.height)

    this.YAxis.call(this.yaxis)
        .selectAll('text')
          .attr('x', 0)
          .attr('dy', 16)

    this.XAxis.call(this.xaxis)
        .selectAll('text')
        .attr('dy', 7)

    this.path.datum(this.data)
        .attr('class', 'line')
        .attr('d', this.line)

    return (<RD3Component data={this.node} />)
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
