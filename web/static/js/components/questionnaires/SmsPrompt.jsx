import React, { Component, PropTypes } from 'react'
import { InputWithLabel } from '../ui'
import classNames from 'classnames/bind'

class SmsPrompt extends Component {

  render() {
    const { id, value, inputErrors, onChange, onBlur } = this.props

    const maybeInvalidClass = classNames({
      'validate invalid': inputErrors != null && inputErrors.length > 0
    })

    return (
      <div className='row'>
        <div className='col input-field s12'>
          <InputWithLabel id={id} value={value} label='SMS message' errors={inputErrors} >
            <input
              type='text'
              is length='140'
              onChange={e => onChange(e)}
              onBlur={e => onBlur(e)}
              ref={ref => {
                $(ref).characterCounter()
                $(ref).addClass(maybeInvalidClass)
              }}
              class={maybeInvalidClass}
              />
          </InputWithLabel>
        </div>
      </div>
    )
  }
}

SmsPrompt.propTypes = {
  id: PropTypes.string.isRequired,
  value: PropTypes.string.isRequired,
  inputErrors: PropTypes.array,
  onChange: PropTypes.func.isRequired,
  onBlur: PropTypes.func.isRequired
}

export default SmsPrompt
