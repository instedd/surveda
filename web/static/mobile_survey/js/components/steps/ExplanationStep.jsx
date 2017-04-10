import React, { Component, PropTypes } from 'react'
import Prompt from '../Prompt'

class ExplanationStep extends Component {
  getValue() {
    return ''
  }

  render() {
    const { step } = this.props
    return (
      <div>
        <Prompt text={step.prompt} />
        <br />
        <input type='submit' value='>' />
      </div>
    )
  }
}

ExplanationStep.propTypes = {
  step: PropTypes.object
}

export default ExplanationStep

