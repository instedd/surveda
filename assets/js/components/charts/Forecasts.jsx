import React, { Component } from "react"
import * as d3 from "d3"
import References from "./References"
import TimeAgo from "react-timeago"
import { percentFormat } from "./utils"

const margin = { left: 36, top: 18, right: 18, bottom: 36 }

type Props = {
  ceil: number,
  data: Array<Object>,
}

export default class Forecasts extends Component<Props> {
  constructor(props) {
    super(props)

    this.recalculate = this.recalculate.bind(this)
    this.state = {
      width: 0,
      height: 0,
      data: props.data,
      forecastEndDate: this.getForecastEndDate(props),
    }
  }

  getForecastEndDate(props) {
    const { data } = this.props
    return d3.max(data, (d) => (d.forecast.length ? d.forecast[d.forecast.length - 1].time : null))
  }

  recalculate() {
    const { container } = this.refs
    const containerRect = container.getBoundingClientRect()

    const width = Math.round(containerRect.width) - margin.left - margin.right
    const height = Math.round(width / 2)

    this.setState({ width, height })
  }

  componentDidMount() {
    window.addEventListener("resize", this.recalculate)
    this.recalculate()
    this.renderD3(true)
  }

  componentDidUpdate() {
    this.renderD3()
  }

  componentWillReceiveProps(props) {
    this.setState({
      data: props.data,
      forecastEndDate: this.getForecastEndDate(props),
    })
  }

  componentWillUnmount() {
    window.removeEventListener("resize", this.recalculate)
  }

  renderD3(initial = false) {
    const { ceil } = this.props
    const { width, height, data } = this.state

    const flatten = Array.prototype.concat(...data.map((d) => [...d.values, ...d.forecast]))

    let initialTime, lastTime

    if (!flatten || flatten.length < 1) {
      initialTime = new Date()
      lastTime = d3.timeMonth.offset(initialTime, 1)
    } else {
      initialTime = d3.timeHour.offset(
        d3.min(flatten, (d) => d.time),
        -1
      )
      lastTime = d3.timeMonth.offset(initialTime, 1)
      lastTime = d3.max([d3.max(flatten, (d) => d.time), lastTime])
    }

    const x = d3.scaleTime().domain([initialTime, lastTime]).range([0, width])
    const y = d3
      .scaleLinear()
      .domain([0, d3.max([d3.max(flatten, (d) => d.value), ceil])])
      .range([height, 0])
    const line = d3
      .line()
      .x((d) => x(d.time))
      .y((d) => y(d.value))

    var tooltip = d3
      .select("body")
      .append("div")
      .classed("forecast-tooltip", true)
      .style("visibility", "hidden")

    for (var i = 0; i < data.length; i++) {
      for (var j = 0; j < data[i].values.length; j++) {
        if (y(data[i].values[j].value) != 0 && x(data[i].values[j].time) != 0) {
          d3.select(this.refs.circles)
            .selectAll("path")
            .data([data[i].values[j]])
            .enter()
            .append("circle")
            .attr("cx", (d) => x(d.time))
            .attr("cy", (d) => y(d.value))
            .attr("r", "3px")
            .style("fill", data[i].color)
            .style("stroke", data[i].color)
            .on("mouseover", (d) =>
              tooltip
                .text(percentFormat(d.value / 100))
                .style("top", d3.event.pageY - 10 + "px")
                .style("left", d3.event.pageX + 10 + "px")
                .style("visibility", "visible")
            )
            .on("mouseout", () => tooltip.style("visibility", "hidden"))
        }
      }
    }

    const lineClick = function (d) {
      d3.selectAll(".line").classed("clicked-line", false)
      d3.selectAll(`[data-line-id='${this.dataset.lineId}']`).classed("clicked-line", true)
    }

    d3.select(this.refs.values)
      .selectAll("path")
      .data(data)
      .enter()
      .append("path")
      .merge(d3.select(this.refs.values).selectAll("path"))
      .attr("class", "line")
      .attr("data-line-id", (d) => d.id)
      .attr("stroke", (d) => d.color)
      .datum((d) => d.values)
      .attr("d", line)
      .on("click", lineClick)

    d3.select(this.refs.forecasts)
      .selectAll("path")
      .data(data)
      .enter()
      .append("path")
      .merge(d3.select(this.refs.forecasts).selectAll("path"))
      .attr("class", "dotted line")
      .attr("data-line-id", (d) => d.id)
      .attr("stroke", (d) => d.color)
      .datum((d) => {
        return d.forecast
      })
      .attr("d", line)
      .on("click", lineClick)

    d3.select(this.refs.x)
      .attr("class", "axis")
      .call(d3.axisBottom(x).ticks(width / 120))
      .selectAll("text")
      .attr("fill", null)

    d3.select(this.refs.y)
      .attr("class", "axis")
      .call(
        d3
          .axisLeft(y)
          .ticks(height / 60)
          .tickSizeInner(0)
          .tickFormat(d3.format(".2s"))
      )
      .selectAll("text")
      .attr("fill", null)
      .attr("dy", null)

    d3.select(this.refs.grid)
      .attr("class", "grid")
      .call(
        d3
          .axisRight(y)
          .tickSizeInner(width)
          .ticks(height / 60)
      )
      .selectAll("text")
      .remove()
  }

  render() {
    const { data, forecastEndDate } = this.state
    const { width, height } = this.state
    const padding = 6

    return (
      <div className="forecasts" ref="container">
        <svg
          ref="svg"
          width={width + margin.left + margin.right}
          height={height + margin.top + margin.bottom + padding}
        >
          <g transform={`translate(${margin.left},${margin.top})`}>
            <g ref="grid" />
            <g ref="circles" />
            <g ref="values" />
            <g ref="forecasts" />
            <g ref="x" transform={`translate(0,${height})`} />
            <g ref="y" />
          </g>
        </svg>
        <div className="bottom">
          <div />
          {forecastEndDate ? (
            <div className="status">
              <span className="icon">event</span>
              <TimeAgo minPeriod="10" date={forecastEndDate} />
            </div>
          ) : (
            ""
          )}
          <References
            data={data.map((serie) => ({
              label: serie.label,
              color: serie.color,
            }))}
          />
        </div>
      </div>
    )
  }
}
