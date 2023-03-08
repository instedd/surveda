import React, { Component } from "react"
import * as d3 from "d3"
import References from "./References"
import TimeAgo from "react-timeago"

const margin = { left: 36, top: 18, right: 18, bottom: 36 }

type Props = {
  forecast: Array<Object>,
}

export default class SuccessRateLine extends Component<Props> {
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
    const { data, forecast } = this.props
    return d3.max(data, (d) => (d.forecast.length ? d.forecast[d.forecast.length - 1].time : null))
  }

  recalculate() {
    const { container } = this.refs
    const containerRect = container.getBoundingClientRect()

    const width = Math.round(containerRect.width) - margin.left - margin.right
    const height = Math.round(width / 4)

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
    const { width, height, data } = this.state

    let srData = data.filter((d) => d.label === "Success rate")
    srData[0].values.unshift({ time: srData[0].values[0].time, value: 0 })
    srData[0].values.push({ time: srData[0].values[srData[0].values.length - 1].time, value: 0 })

    const flatten = Array.prototype.concat(...srData.map((d) => [...d.values, ...d.forecast]))

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
      .domain([0, d3.max(srData[0].values, (d) => d.value * 1.2)])
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

    for (var i = 0; i < srData.length; i++) {
      for (var j = 1; j < srData[i].values.length - 1; j++) {
        if (y(srData[i].values[j].value) != 0 && x(srData[i].values[j].time) != 0) {
          d3.select(this.refs.circles)
            .selectAll("path")
            .data([srData[i].values[j]])
            .enter()
            .append("circle")
            .attr("cx", (d) => x(d.time))
            .attr("cy", (d) => y(d.value))
            .attr("r", "3px")
            .style("fill", srData[i].color)
            .style("stroke", srData[i].color)
            .style("opacity", 0.1)
            .on("mouseover", (d) =>
              tooltip
                .text(d.value)
                .style("top", d3.event.pageY - 10 + "px")
                .style("left", d3.event.pageX + 10 + "px")
                .style("visibility", "visible")
            )
            .on("mouseout", () => tooltip.style("visibility", "hidden"))
        }
      }
    }

    d3.select(this.refs.values)
      .selectAll("path")
      .data(srData)
      .enter()
      .append("path")
      .merge(d3.select(this.refs.values).selectAll("path"))
      .attr("class", "area")
      .attr("stroke", (d) => d.color)
      .attr("fill", (d) => d.color)
      .datum((d) => d.values)
      .attr("d", line)

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
            <g ref="values" />
            <g ref="circles" />
            <g ref="forecasts" />
            <g ref="x" transform={`translate(0,${height})`} />
            <g ref="y" />
          </g>
        </svg>
      </div>
    )
  }
}
