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
    const { step, onRefusal } = this.props

    let refusalComponent = null
    console.log(step)
    console.log(step.refusal)

    if (step.refusal) {
      refusalComponent = (
        <div>
          <a href='#' onClick={e => { e.preventDefault(); onRefusal(step.refusal) }}>{step.refusal}</a>
        </div>
      )
    }

    return (
      <div>
        <div>
          {(step.prompts || []).map(prompt =>
            <Prompt key={prompt} text={prompt} />
          )}
          <div className='input-button-inline'>
            <input type='number' value={this.state.value} onChange={this.handleChange} min={step.min} max={step.max} />
            <button className='btn square' disabled={!this.state.valid}>
              <svg height='24' viewBox='0 0 24 24' width='24' xmlns='http://www.w3.org/2000/svg'>
                <path d='M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z' />
              </svg>
            </button>
          </div>
        </div>
        {refusalComponent}
      </div>
    )
  }
}

NumericStep.propTypes = {
  step: PropTypes.object,
  onRefusal: PropTypes.func
}

export default NumericStep

