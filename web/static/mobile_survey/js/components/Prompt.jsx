// @flow
import React, { Component, PropTypes } from 'react'

class Prompt extends Component {
  render() {
    const { text } = this.props
    return <div className={'prompt'}><h1 dangerouslySetInnerHTML={{__html: text}} /></div>
  }
}

Prompt.propTypes = {
  text: PropTypes.string
}

export default Prompt
