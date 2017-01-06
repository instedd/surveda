// @flow
import React, { Component, PropTypes } from 'react'

export class ScrollToLink extends Component {
  static propTypes = {
    target: PropTypes.string.isRequired,
    children: PropTypes.node
  }

  render() {
    const { children, target } = this.props

    return <a href='#' className='scrollToLink' onClick={(e) => animatedScrollTo(e, target)}>
      <i className='material-icons'>keyboard_arrow_down</i>
      <span>{children}</span>
    </a>
  }
}

export const animatedScrollTo = (e: Event, target: String) => {
  e.preventDefault()

  $('html, body').animate({
    scrollTop: $(target).offset().top
  }, 500)
}
