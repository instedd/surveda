import React, { Component, PropTypes } from 'react'
import { InputWithLabel } from '../ui'
import classNames from 'classnames/bind'

class SmsPrompt extends Component {

  render() {
    const { id, value, inputErrors, onChange, onBlur } = this.props

    return (
      <div className='row'>
        <div className='col input-field s12'>
          <InputWithLabel id={id} value={value} label='SMS message' errors={inputErrors} >
            <input
              type='text'
              is length='140'
              onChange={e => onChange(e)}
              onBlur={e => onBlur(e)}
              ref={ref => $(ref).characterCounter()}
              class={classNames({'invalid': inputErrors})}
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
  inputErrors: PropTypes.bool,
  onChange: PropTypes.func.isRequired,
  onBlur: PropTypes.func.isRequired
}

export default SmsPrompt
