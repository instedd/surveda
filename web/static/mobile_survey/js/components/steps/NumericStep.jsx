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

  clearValue() {
    this.setState({value: '', valid: false})
  }

  render() {
    const { step, errorMessage } = this.props
    const hasError = this.state.value != '' && !this.state.valid

    let errorDiv = null
    let inputClassName = null
    if (hasError) {
      inputClassName = 'error'
      errorDiv = (
        <div className='error-message'>
          {errorMessage}
        </div>
      )
    }

    return (
      <div>
        {(step.prompts || []).map(prompt =>
          <Prompt key={prompt} text={prompt} />
        )}
        <div className='input-button-inline'>
          <input type='number' value={this.state.value} onChange={this.handleChange} min={step.min} max={step.max} className={inputClassName} />
          <button className='btn square' disabled={!this.state.valid}>
            <svg height='24' viewBox='0 0 24 24' width='24' xmlns='http://www.w3.org/2000/svg'>
              <path d='M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z' />
            </svg>
          </button>
          {errorDiv}
        </div>
      </div>
    )
  }
}

NumericStep.propTypes = {
  step: PropTypes.object,
  errorMessage: PropTypes.string
}

export default NumericStep

