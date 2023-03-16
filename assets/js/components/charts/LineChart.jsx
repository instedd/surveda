import React, { Component } from "react"
import * as d3 from "d3"

const margin = { left: 36, top: 18, right: 18, bottom: 36 }

type Props = {
  data: Array<Object>,
}

export default class LineChart extends Component<Props> {
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
    const { variable } = this.props

    const flatten = Object.entries(data).map((d) => {
      return {
        time: new Date(d[1]["insertedAt"]),
        value: d[1][variable].length,
        color: "black",
        k: d[1].id,
        v: d[1],
      }
    })

    let initialTime = d3.min(flatten, (d) => d.time)
    let lastTime = d3.max(flatten, (d) => d.time)

    const x = d3.scaleTime().domain([initialTime, lastTime]).range([0, width])
    const y = d3
      .scaleLinear()
      .domain([0, d3.max(flatten, (d) => d.value * 1.2)])
      .range([height, 0])
    const line = d3
      .line()
      .x((d) => x(d.date))
      .y((d) => y(d.value))

    var tooltip = d3
      .select("body")
      .append("div")
      .classed("forecast-tooltip", true)
      .style("visibility", "hidden")

    for (var i = 0; i < flatten.length; i++) {
      if (y(flatten[i].value) != 0 && x(flatten[i].time) != 0) {
        d3.select(this.refs.circles)
          .selectAll("path")
          .data([flatten[i]])
          .enter()
          .append("circle")
          .attr("cx", (d) => x(d.time))
          .attr("cy", (d) => y(d.value))
          .attr("r", "3px")
          .style("fill", flatten[i].color)
          .style("stroke", flatten[i].color)
          .style("opacity", 0.1)
          .on("mouseover", (d) =>
            tooltip
              .text(JSON.stringify(d.v, null, 2))
              .style("top", d3.event.pageY - 10 + "px")
              .style("left", d3.event.pageX + 10 + "px")
              .style("visibility", "visible")
          )
          .on("mouseout", () => tooltip.style("visibility", "hidden"))
      }
    }

    const xAxis = d3.axisBottom(x).ticks(width / 120)

    d3.select(this.refs.x).attr("class", "axis").call(xAxis).selectAll("text").attr("fill", null)

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

    // Zoom on the chart only making use of the x axis (time)
    // Keep the circle radius constant
    const zoom = d3
      .zoom()
      .scaleExtent([1, 100])
      .translateExtent([
        [0, 0],
        [width, height],
      ])
      .extent([
        [0, 0],
        [width, height],
      ])
      .on("zoom", () => {
        const t = d3.event.transform
        const newX = t.rescaleX(x)
        xAxis.scale(newX)
        d3.select(this.refs.x).call(xAxis)
        d3.select(this.refs.grid)
          .call(
            d3
              .axisRight(y)
              .tickSizeInner(width)
              .ticks(height / 60)
          )
          .selectAll("text")
          .remove()
        d3.select(this.refs.circles)
          .selectAll("circle")
          .attr("cx", (d) => newX(d.time))
      })

    d3.select(this.refs.svg).call(zoom)
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
