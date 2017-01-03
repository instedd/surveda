import React, { Component, PropTypes } from 'react'
import { InputWithLabel, Autocomplete } from '../ui'
import classNames from 'classnames/bind'

class SmsPrompt extends Component {
  onBlur(e) {
    if (this.refs.autocomplete.clickingAutocomplete) return
    this.refs.autocomplete.hide()

    const { onBlur } = this.props
    onBlur(e)
  }

  render() {
    const { id, value, inputErrors, onChange, autocompleteGetData, autocompleteOnSelect } = this.props

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
              onBlur={e => this.onBlur(e)}
              ref={ref => {
                this.smsInput = ref
                $(ref).characterCounter()
                $(ref).addClass(maybeInvalidClass)
              }}
              class={maybeInvalidClass}
              />
            <Autocomplete
              getInput={() => this.smsInput}
              getData={(value, callback) => autocompleteGetData(value, callback)}
              onSelect={(item) => autocompleteOnSelect(item)}
              ref='autocomplete'
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
  onBlur: PropTypes.func.isRequired,
  autocompleteGetData: PropTypes.func.isRequired,
  autocompleteOnSelect: PropTypes.func.isRequired
}

export default SmsPrompt
