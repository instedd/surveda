import React, { Component } from 'react'
import rd3 from 'react-d3-library'
const RD3Component = rd3.Component

class RespondentsChart extends Component {
  constructor(props) {
    super(props)
    this.state = { d3: '' }
  }

  static propTypes = {
    completedByDate: React.PropTypes.array.isRequired
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
    this.setData(nextProps.completedByDate)
  }

  setData(completedByDate) {
    if (!completedByDate || completedByDate.length < 1) {
      return
    }
    const initialDate = new Date(Date.parse(completedByDate[0].date))
    const nextThreeMonths = new Date(Date.parse(completedByDate[0].date))
    nextThreeMonths.setDate(nextThreeMonths.getDate() + 90)
    const lastDate = new Date(Math.max(Date.parse(completedByDate[completedByDate.length - 1].date), nextThreeMonths))
    const formatDate = function(date) { return new Date(Date.parse(date)) }
    this.data = completedByDate.map((d) => { return { date: formatDate(d.date), count: Number(d.count) } });
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

    this.XAxis.call(this.xaxis)
        .selectAll('text')
        .attr('dy', 7)

    this.path.datum(this.data)
        .attr('class', 'line respondentsData')
        .attr('d', this.line)

    this.backgroundPath.datum(this.backgroundData)
        .attr('class', 'line backgroundData')
        .attr('d', this.line)
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
                        .ticks(4)

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

    const { completedByDate } = this.props
    const node = document.createElement('div')
    this.svg = d3.select(node).append('svg')

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
