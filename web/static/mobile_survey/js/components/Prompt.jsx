import React, { Component, PropTypes } from 'react'

class Prompt extends Component {
  render() {
    const { text } = this.props
    return <div>{text}</div>
  }
}

Prompt.propTypes = {
  text: PropTypes.string
}

export default Prompt

