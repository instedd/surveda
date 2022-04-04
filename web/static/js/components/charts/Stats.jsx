import React, { Component } from "react"
import * as d3 from "d3"

const formatter = d3.format(",")

type Props = {
  data: Array<Object>,
}

export default class Stats extends Component<Props> {
  render() {
    const { data } = this.props

    return (
      <div className="stats">
        {data.map((item, index) => {
          return (
            <div key={index}>
              {formatter(item.value)}
              <span className="label">{item.label}</span>
            </div>
          )
        })}
      </div>
    )
  }
}
