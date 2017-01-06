// @flow
import React, { Component, PropTypes } from 'react'

export class ScrollToLink extends Component {
  static propTypes = {
    target: PropTypes.string.isRequired,
    children: PropTypes.node
  }

  scrollToLink() {
    const { target } = this.props

    $('html, body').animate({
      scrollTop: $(target).offset().top
    }, 500)
    event.preventDefault()
  }

  render() {
    const { children } = this.props

    return <a href='#' className='scrollToLink' onClick={() => this.scrollToLink()}>
      <i className='material-icons'>keyboard_arrow_down</i>
      <span>{children}</span>
    </a>
  }
}
