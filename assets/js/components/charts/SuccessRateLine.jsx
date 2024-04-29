import React, { Component } from "react"
import * as d3 from "d3"
import { percentFormat } from "./utils"

const margin = { left: 36, top: 18, right: 18, bottom: 36 }

type Props = {
  data: Array<Object>,
}

export default class SuccessRateLine extends Component<Props> {
  constructor(props) {
    super(props)

    this.recalculate = this.recalculate.bind(this)
    this.state = {
      width: 0,
      height: 0,
      data: props.data,
    }
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
    })
  }

  componentWillUnmount() {
    window.removeEventListener("resize", this.recalculate)
  }

  renderD3(initial = false) {
    const { width, height, data } = this.state

    if (!data){
      return
    }

    let initialTime, lastTime

    if (!data.values || data.values.length < 1) {
      initialTime = new Date()
      lastTime = d3.timeMonth.offset(initialTime, 1)
    } else {
      initialTime = d3.timeHour.offset(
        d3.min(data.values, (d) => d.time),
        -1
      )
      const oneMonthFromStart = d3.timeMonth.offset(initialTime, 1)
      lastTime = d3.max([d3.max(data.values, (d) => d.time), oneMonthFromStart])
    }

    const x = d3.scaleTime().domain([initialTime, lastTime]).range([0, width])
    const y = d3
      .scaleLinear()
      .domain([0, d3.max(data.values, (d) => d.value * 1.2)])
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

    for (var j = 1; j < data.values.length - 1; j++) {
      if (y(data.values[j].value) != 0 && x(data.values[j].time) != 0) {
        d3.select(this.refs.circles)
          .selectAll("path")
          .data([data.values[j]])
          .enter()
          .append("circle")
          .attr("cx", (d) => x(d.time))
          .attr("cy", (d) => y(d.value))
          .attr("r", "3px")
          .style("fill", data.color)
          .style("stroke", data.color)
          .style("opacity", 0.2)
          .on("mouseover", (d) => {
            tooltip
              .text(percentFormat(d.value / 100))
              .style("top", d3.event.pageY - 10 + "px")
              .style("left", d3.event.pageX + 10 + "px")
              .style("visibility", "visible")
          })
          .on("mouseout", () => tooltip.style("visibility", "hidden"))
      }
    }

    d3.select(this.refs.values)
      .selectAll("path")
      .data([data])
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
