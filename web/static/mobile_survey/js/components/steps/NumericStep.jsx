// @flow
import React, { Component, PropTypes } from 'react'
import Prompt from '../Prompt'

type State = {
  value: string,
  valid: boolean
};

class NumericStep extends Component {
  state: State
  handleChange: PropTypes.func.isRequired

  constructor(props: any) {
    super(props)
    this.state = {value: '', valid: false}

    this.handleChange = this.handleChange.bind(this)
  }

  handleChange(event: any) {
    const { step } = this.props
    const { value } = event.target
    const intValue = parseInt(value)
    const valid = (step.min == null || intValue >= step.min) && (step.max == null || intValue <= step.max)
    this.setState({value, valid})
  }

  getValue() {
    return this.state.value
  }

  render() {
    const { step } = this.props
    return (
      <div>
        {(step.prompts || []).map(prompt =>
          <Prompt key={prompt} text={prompt} />
        )}
        <br />
        <div>
          <input type='number' value={this.state.value} onChange={this.handleChange} min={step.min} max={step.max} />
        </div>
        <br />
        <input type='submit' value='>' disabled={!this.state.valid} />
      </div>
    )
  }
}

NumericStep.propTypes = {
  step: PropTypes.object
}

export default NumericStep

