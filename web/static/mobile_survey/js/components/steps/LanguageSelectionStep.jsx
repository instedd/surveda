// @flow
import React, { Component, PropTypes } from 'react'
import Prompt from '../Prompt'

class LanguageSelectionStep extends Component {
  getValue() {
    return this.refs.select.value
  }

  render() {
    const { step } = this.props
    return (
      <div>
        {step.prompts.map(prompt =>
          <Prompt key={prompt} text={prompt} />
        )}
        <select ref='select'>
          {step.choices.map(choice => {
            return <option key={choice} value={choice}>{choice}</option>
          })}
        </select>
        <input className='btn block' type='submit' value='Next' />
      </div>
    )
  }
}

LanguageSelectionStep.propTypes = {
  step: PropTypes.object
}

export default LanguageSelectionStep

