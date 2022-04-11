// @flow
import React, { Component } from "react"

type Props = {
  target: string,
  children: any,
}

export class ScrollToLink extends Component<Props> {
  render() {
    const { children, target } = this.props

    return (
      <a href="#" className="scrollToLink" onClick={(e) => animatedScrollTo(e, target)}>
        <i className="material-icons">keyboard_arrow_down</i>
        <span>{children}</span>
      </a>
    )
  }
}

export const animatedScrollTo = (e: Event, target: string) => {
  e.preventDefault()

  $("html, body").animate(
    {
      scrollTop: $(target).offset().top,
    },
    500
  )
}
