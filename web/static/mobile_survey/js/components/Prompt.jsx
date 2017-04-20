// @flow
import React, { Component, PropTypes } from 'react'

class Prompt extends Component {
  render() {
    const { text } = this.props
    return <div className={'prompt'}><h1>{text}</h1></div>
  }
}

Prompt.propTypes = {
  text: PropTypes.string
}

export default Prompt
