// @flow
import React, { Component } from "react"

type Props = {
  children: any,
  offset: number,
}

export class PositionFixer extends Component<Props> {
  recalculate: Function

  constructor(props: Props) {
    super(props)
    this.recalculate = this.recalculate.bind(this)
  }

  static defaultProps = {
    offset: 0,
  }

  componentDidMount() {
    window.addEventListener("scroll", this.recalculate)
    window.addEventListener("resize", this.recalculate)
    this.recalculate()
  }

  componentWillUnmount() {
    window.removeEventListener("scroll", this.recalculate)
    window.removeEventListener("resize", this.recalculate)
  }

  recalculate() {
    const { offset } = this.props
    const { reference, contents } = this.refs
    const referenceRect = reference.getBoundingClientRect()

    // Setting decimal pixels produces small imperfections in the UI
    // Because parent element might have sizes specified in percentages
    // we copy the rounded value even when the position is not pinned.
    // This way we ensure the same box size when pinned.
    contents.style.width = `${Math.round(referenceRect.width)}px`

    if (referenceRect.top < offset) {
      contents.style.position = "fixed"
      contents.style.top = `${offset}px`
    } else {
      contents.style.position = null
      contents.style.top = null
    }
  }

  render() {
    const { children } = this.props

    // This is to avoid margin collapsing that would affect position calculation
    // https://www.w3.org/TR/CSS2/box.html#collapsing-margins
    const referenceStyle = {
      paddingTop: "1px",
      marginTop: "-1px",
    }

    return (
      <div>
        <div ref="reference" style={referenceStyle} />
        <div ref="contents">{children}</div>
      </div>
    )
  }
}
