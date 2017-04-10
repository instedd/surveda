// @flow
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
        {(step.prompts || []).map(prompt =>
          <Prompt key={prompt} text={prompt} />
        )}
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
