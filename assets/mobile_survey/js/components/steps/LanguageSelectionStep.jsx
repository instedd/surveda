// @flow
import React, { Component, PropTypes } from "react"
import Prompt from "../Prompt"
import languageNames from "language-names"

type Props = {
  step: Object,
  onClick: Function,
}

class LanguageSelectionStep extends Component<Props> {
  getValue() {
    return this.refs.select.value
  }

  clearValue() {}

  render() {
    const { step, onClick } = this.props
    return (
      <div>
        {(step.prompts || []).map((prompt) => (
          <Prompt key={prompt} text={prompt} />
        ))}
        {step.choices.map((choice, index) => {
          return (
            <div key={choice}>
              <button
                className="btn block"
                value={choice}
                onClick={(e) => {
                  e.preventDefault()
                  onClick(index + 1)
                }}
              >
                {languageNames[choice]}
              </button>
            </div>
          )
        })}
      </div>
    )
  }
}

export default LanguageSelectionStep
