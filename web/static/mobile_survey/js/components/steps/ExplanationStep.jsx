import React, { Component, PropTypes } from 'react'
import Prompt from '../Prompt'
import * as actions from '../../actions/step'

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
        <input type='submit' value='Next' />
      </div>
    )
  }
}

ExplanationStep.propTypes = {
  step: PropTypes.object
}

export default ExplanationStep

