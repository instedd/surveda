// @flow
import React, { Component, PropTypes } from 'react'
import Prompt from '../Prompt'

class MultipleChoiceStep extends Component {
  getValue() {
    return this.refs.select.value
  }

  classNameForChoice(choice: String) {
    const length = choice.length
    let cssClass
    switch (true) {
      case (length < 7):
        cssClass = 'choice-length-less-7'
        break
      case (length < 14):
        cssClass = 'choice-length-less-14'
        break
      case (length < 20):
        cssClass = 'choice-length-less-20'
        break
      case (length < 40):
        cssClass = 'choice-length-less-40'
        break
      case (length < 60):
        cssClass = 'choice-length-less-60'
        break
      default:
        cssClass = 'choice-length-large'
    }
    return cssClass
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
              <button className={'btn block ' + this.classNameForChoice(choice[0])} value={choice} onClick={e => { e.preventDefault(); onClick(choice) }}>{choice}</button>
            </div>
          )
        })}
      </div>
    )
  }
}

MultipleChoiceStep.propTypes = {
  step: PropTypes.object,
  onClick: PropTypes.func
}

export default MultipleChoiceStep
