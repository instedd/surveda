import React, { Component } from "react"
import * as d3 from "d3"

type Props = {
  weight: number,
  width: number,
  height: number,
  value: number,
  semi: boolean,
  color: string,
}

export default class Donut extends Component<Props> {
  componentDidMount() {
    this.d3Render()
  }

  componentDidUpdate() {
    this.d3Render()
  }

  d3Render() {
    const { width, height, value, semi, weight } = this.props
    const tau = Math.PI * (semi ? 1 : 2)
    const radius = Math.min(width / 2, semi ? height : height / 2)
    const angle = value * tau
    const offset = semi ? tau / 2 : 0

    const arc = d3
      .arc()
      .outerRadius(radius)
      .innerRadius(radius - weight)
      .startAngle(-offset)

    d3.select(this.refs.background)
      .datum({ endAngle: tau - offset })
      .attr("d", arc)

    d3.select(this.refs.foreground)
      .datum({ endAngle: angle - offset })
      .attr("d", arc)
  }

  render() {
    const { width, height, semi, color } = this.props
    const radius = Math.min(width / 2, semi ? height : height / 2)

    return (
      <svg className="donut" width={width} height={height}>
        <g ref="container" transform={`translate(${radius}, ${radius})`}>
          <path className="background" ref="background" />
          <path className={color} ref="foreground" />
        </g>
      </svg>
    )
  }
}
