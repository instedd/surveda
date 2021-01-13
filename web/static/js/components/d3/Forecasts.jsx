import React, { Component } from 'react'
import * as d3 from 'd3'
import References from './References'
import TimeAgo from 'react-timeago'

const margin = {left: 36, top: 18, right: 18, bottom: 36}

type Props = {
  ceil: number,
  forecast: Array<Object>
}

export default class Forecasts extends Component<Props> {
  constructor(props) {
    super(props)

    this.recalculate = this.recalculate.bind(this)
    const data = this.forecast(props)
    this.state = {
      width: 0,
      height: 0,
      data: data,
      forecastEndDate: this.getForecastEndDate(data, props)
    }
  }

  forecast(props) {
    let {data, ceil, forecast} = props
    return data.map(d => {
      if (this.shouldForecast(d, ceil, forecast)) {
        return {...d, forecast: this.getForecast(d.values[0], d.values[d.values.length - 1], ceil)}
      } else {
        return {...d, forecast: []}
      }
    })
  }

  getForecastEndDate(data, props) {
    const {ceil, forecast} = this.props
    return d3.max(data, d => this.shouldForecast(d, ceil, forecast) ? d.forecast[d.forecast.length - 1].time : null)
  }

  shouldForecast(data, ceil, forecast) {
    return forecast &&
      data.values.length > 1 &&
      ceil > data.values[data.values.length - 1].value &&
      data.values[data.values.length - 1].value > data.values[0].value &&
      data.values[0].time < data.values[data.values.length - 1].time
  }

  recalculate() {
    const { container } = this.refs
    const containerRect = container.getBoundingClientRect()

    const width = Math.round(containerRect.width) - margin.left - margin.right
    const height = Math.round(width / 2)

    this.setState({width, height})
  }

  componentDidMount() {
    window.addEventListener('resize', this.recalculate)
    this.recalculate()
    this.renderD3(true)
  }

  componentDidUpdate() {
    this.renderD3()
  }

  componentWillReceiveProps(props) {
    const data = this.forecast(props)
    this.setState({data: data, forecastEndDate: this.getForecastEndDate(data, props)})
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.recalculate)
  }

  getForecast(firstValue, lastValue, ceil) {
    const slope = (lastValue.value - firstValue.value) / (lastValue.time - firstValue.time)
    return [lastValue, {value: ceil, time: new Date(firstValue.time.getTime() + (ceil / slope))}]
  }

  renderD3(initial = false) {
    const {ceil} = this.props
    const {width, height, data} = this.state
    const flatten = Array.prototype.concat(...data.map(d => [...d.values, ...d.forecast]))

    let initialTime, lastTime

    if (!flatten || flatten.length < 1) {
      initialTime = new Date()
      lastTime = d3.timeMonth.offset(initialTime, 1)
    } else {
      initialTime = d3.min(flatten, d => d.time)
      lastTime = d3.timeMonth.offset(initialTime, 1)
      lastTime = d3.max([d3.max(flatten, d => d.time), lastTime])
    }

    const x = d3.scaleTime().domain([initialTime, lastTime]).range([0, width])
    const y = d3.scaleLinear().domain([0, d3.max([d3.max(flatten, d => d.value), ceil])]).range([height, 0])
    const line = d3.line()
      .x(d => x(d.time))
      .y(d => y(d.value))

    d3.select(this.refs.values)
        .selectAll('path')
        .data(data)
      .enter()
        .append('path')
        .merge(d3.select(this.refs.values).selectAll('path'))
        .attr('class', 'line')
        .attr('stroke', d => d.color)
        .datum(d => d.values)
        .attr('d', line)

    d3.select(this.refs.forecasts)
        .selectAll('path')
        .data(data)
      .enter()
        .append('path')
        .merge(d3.select(this.refs.forecasts).selectAll('path'))
        .attr('class', 'dotted line')
        .attr('stroke', d => d.color)
        .datum(d => {
          return d.forecast
        })
        .attr('d', line)

    d3.select(this.refs.x)
      .attr('class', 'axis')
      .call(d3.axisBottom(x).ticks(width / 120))
      .selectAll('text')
      .attr('fill', null)

    d3.select(this.refs.y)
      .attr('class', 'axis')
      .call(d3.axisLeft(y).ticks(height / 60).tickSizeInner(0).tickFormat(d3.format('.2s')))
      .selectAll('text')
      .attr('fill', null)
      .attr('dy', null)

    d3.select(this.refs.grid)
      .attr('class', 'grid')
      .call(d3.axisRight(y).tickSizeInner(width).ticks(height / 60))
      .selectAll('text')
      .remove()
  }

  render() {
    const {data, forecastEndDate} = this.state
    const {width, height} = this.state
    const padding = 6

    return (
      <div className='forecasts' ref='container'>
        <svg ref='svg' width={width + margin.left + margin.right} height={height + margin.top + margin.bottom + padding}>
          <g transform={`translate(${margin.left},${margin.top})`}>
            <g ref='grid' />
            <g ref='values' />
            <g ref='forecasts' />
            <g ref='x' transform={`translate(0,${height})`} />
            <g ref='y' />
          </g>
        </svg>
        <div className='bottom'>
          <div />
          { forecastEndDate
            ? <div className='status'><span className='icon'>event</span><TimeAgo minPeriod='10' date={forecastEndDate} /></div>
            : ''}
          <References data={data.map(serie => ({label: serie.label, color: serie.color}))} />
        </div>
      </div>
    )
  }
}
