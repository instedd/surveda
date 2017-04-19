// @flow
import React, { Component, PropTypes } from 'react'
import Prompt from '../Prompt'

class LanguageSelectionStep extends Component {
  getValue() {
    return this.refs.select.value
  }

  clearValue() {}

  render() {
    const { step, onClick } = this.props
    return (
      <div>
        {(step.prompts || []).map(prompt =>
          <Prompt key={prompt} text={prompt} />
        )}
        {step.choices.map((choice, index) => {
          // HACK: skip the first choice because it's always dummy
          if (index == 0) return null

          return (
            <div key={choice} >
              <button className='btn block' value={choice} onClick={e => { e.preventDefault(); onClick(index) }}>{choice}</button>
            </div>
          )
        })}
      </div>
    )
  }
}

LanguageSelectionStep.propTypes = {
  step: PropTypes.object,
  onClick: PropTypes.func
}

export default LanguageSelectionStep

