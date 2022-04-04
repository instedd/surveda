// @flow
import React, { Component, PropTypes } from "react"
import Prompt from "../Prompt"

type Props = {
  step: Object,
}

class EndStep extends Component<Props> {
  getValue() {
    return ""
  }

  clearValue() {}

  render() {
    const { step } = this.props

    return (
      <div>
        {(step.prompts || []).map((prompt) => (
          <Prompt key={prompt} text={prompt} />
        ))}
      </div>
    )
  }
}

export default EndStep
