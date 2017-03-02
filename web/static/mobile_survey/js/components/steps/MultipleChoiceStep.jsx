import React, { Component, PropTypes } from 'react'
import Prompt from '../Prompt'

class MultipleChoiceStep extends Component {
  render() {
    const { step } = this.props
    return (
      <div>
        <Prompt text={step.prompt} />
        <br />
        <div>
          <select>
            {step.choices.map(choice => {
              return <option value={choice}>{choice}</option>
            })}
          </select>
        </div>
        <br />
        <input type='submit' value='Next' />
      </div>
    )
  }
}

MultipleChoiceStep.propTypes = {
  step: PropTypes.object
}

export default MultipleChoiceStep

