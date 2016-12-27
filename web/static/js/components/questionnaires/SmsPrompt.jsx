// @flow
import React, { Component } from 'react'
import classNames from 'classnames/bind'

type Props = {
  id: string,
  value: string,
  inputErrors: ?Array<string>,
  onChange: Function,
  onBlur: Function
}

class SmsPrompt extends Component {
  props: Props
  textInput: HTMLElement
  textLabel: HTMLElement

  maybeInvalidClass() {
    const { inputErrors } = this.props

    return classNames({
      validate: true,
      invalid: inputErrors != null && inputErrors.length > 0
    })
  }

  updateStyles() {
    if (this.textInput && this.textLabel) {
      if ($(this.textLabel).hasClass('active')) {
        $(this.textInput).removeClass(this.maybeInvalidClass())
      } else {
        $(this.textInput).addClass(this.maybeInvalidClass())
      }
    }
  }

  render() {
    const { id, value, inputErrors, onChange, onBlur } = this.props

    let errorMessage = null

    if (inputErrors) {
      errorMessage = inputErrors.join(', ')
    }

    return (
      <div className='row'>
        <div className='col s12'>
          <div className='input-field'>
            <input
              id={id}
              type='text'
              is length='140'
              onChange={e => onChange(e)}
              onBlur={e => onBlur(e)}
              ref={input => {
                $(input).characterCounter()
                this.textInput = input
                this.updateStyles()
              }}
              className={this.maybeInvalidClass()}
              value={value}
              />
            <label
              htmlFor={id}
              className={classNames({'active': value != null && value !== ''})}
              data-error={errorMessage}
              ref={label => {
                this.textLabel = label
                this.updateStyles()
              }}>
              SMS message
            </label>
          </div>
        </div>
      </div>
    )
  }
}

export default SmsPrompt
