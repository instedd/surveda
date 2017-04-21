// @flow
import React, { Component, PropTypes } from 'react'
import Prompt from '../Prompt'

class EndStep extends Component {
  getValue() {
    return ''
  }

  clearValue() {}

  render() {
    const { step } = this.props

    return (
      <div>
        {(step.prompts || []).map(prompt =>
          <Prompt key={prompt} text={prompt} />
        )}
      </div>
    )
  }
}

EndStep.propTypes = {
  step: PropTypes.object
}

export default EndStep
