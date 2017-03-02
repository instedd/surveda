import React, { Component, PropTypes } from 'react'
import Prompt from '../Prompt'

class NumericStep extends Component {
  render() {
    const { step } = this.props
    return (
      <div>
        <Prompt text={step.prompt} />
        <br />
        <div>
          <input type='number' min={step.min} max={step.max} />
        </div>
        <br />
        <input type='submit' value='Next' />
      </div>
    )
  }
}

NumericStep.propTypes = {
  step: PropTypes.object
}

export default NumericStep

