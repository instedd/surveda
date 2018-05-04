// @flow
import React, { Component, PropTypes } from 'react'
import Prompt from '../Prompt'

type Props = {
  step: Object,
  onClick: Function
};

class MultipleChoiceStep extends Component<Props> {
  getValue() {
    return this.refs.select.value
  }

  clearValue() {}

  classNameForButton(choices: Choice[], choice: Choice) {
    // The usage of 16 as limit of multiline was obtained by trial and error.
    // At that count, text start using 2 lines for being displayed.
    const limit = 16
    if (choices.length <= 3) {
      if (choice[0].length > limit) {
        return 'large multiline'
      } else {
        return 'large'
      }
    } else {
      return 'small'
    }
  }

  render() {
    const { step, onClick } = this.props
    return (
      <div>
        {(step.prompts || []).map(prompt =>
          <Prompt key={prompt} text={prompt} />
        )}
        {step.choices.map(choice => {
          return (
            <div key={choice}>
              <button className={'btn block ' + this.classNameForButton(step.choices, choice)} value={choice} onClick={e => { e.preventDefault(); onClick(choice) }} style={{color: this.context.primaryColor, borderColor: this.context.primaryColor}}>{choice}</button>
            </div>
          )
        })}
      </div>
    )
  }
}

MultipleChoiceStep.contextTypes = {
  primaryColor: PropTypes.string
}

export default MultipleChoiceStep
