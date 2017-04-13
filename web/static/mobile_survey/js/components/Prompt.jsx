// @flow
import React, { Component, PropTypes } from 'react'

class Prompt extends Component {
  classNameForPrompt(prompt: String) {
    const length = prompt.length
    let cssClass
    switch (true) {
      case (length < 100):
        cssClass = 'prompt-length-less-100'
        break
      case (length < 200):
        cssClass = 'prompt-length-less-200'
        break
      case (length < 300):
        cssClass = 'prompt-length-less-300'
        break
      case (length < 400):
        cssClass = 'prompt-length-less-400'
        break
      default:
        cssClass = 'prompt-length-large'
    }
    return cssClass
  }

  render() {
    const { text } = this.props
    return <div className={'prompt'}><h1 className={this.classNameForPrompt(text)}>{text}</h1></div>
  }
}

Prompt.propTypes = {
  text: PropTypes.string
}

export default Prompt
