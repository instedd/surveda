import React, { Component, PropTypes } from 'react'
import { InputWithLabel, Autocomplete } from '../ui'
import classNames from 'classnames/bind'

class SmsPrompt extends Component {
  onBlur(e) {
    let autocomplete = this.refs.autocomplete
    if (autocomplete) {
      if (autocomplete.clickingAutocomplete) return
      autocomplete.hide()
    }

    const { onBlur } = this.props
    onBlur(e)
  }

  render() {
    const { id, value, inputErrors, onChange, autocomplete, autocompleteGetData, autocompleteOnSelect } = this.props

    const maybeInvalidClass = classNames({
      'validate invalid': inputErrors != null && inputErrors.length > 0
    })

    let autocompleteComponent = null
    if (autocomplete) {
      autocompleteComponent = (
        <Autocomplete
          getInput={() => this.smsInput}
          getData={(value, callback) => autocompleteGetData(value, callback)}
          onSelect={(item) => autocompleteOnSelect(item)}
          ref='autocomplete'
              />
      )
    }

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
            {autocompleteComponent}
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
  autocomplete: PropTypes.bool.isRequired,
  autocompleteGetData: PropTypes.func,
  autocompleteOnSelect: PropTypes.func}

export default SmsPrompt
