import React, { Component, PropTypes } from 'react'
import { InputWithLabel, Autocomplete } from '../ui'
import classNames from 'classnames/bind'
import { splitSmsText, joinSmsPieces } from '../../step'
import CharacterCounter from '../CharacterCounter'
import {limitExceeded} from '../../characterCounter'

class SmsPrompt extends Component {
  onBlur(e) {
    e.preventDefault()

    let autocomplete = this.refs.autocomplete
    if (autocomplete) {
      if (autocomplete.clickingAutocomplete) return
      autocomplete.hide()
    }

    const { onBlur } = this.props
    onBlur(this.getText())
  }

  onChange(e) {
    e.preventDefault()

    const { onChange } = this.props
    onChange(this.getText())
  }

  checkKeyUp(e, index) {
    if (e.shiftKey && e.key == 'Enter') {
      e.preventDefault()
      this.splitPiece(e, index)
    }
  }

  splitPiece(e, index) {
    let caretIndex = e.target.selectionStart
    let value = e.target.value || ''
    let before = value.slice(0, caretIndex)
    let after = value.slice(caretIndex)

    let pieces = this.allInputs.map(x => (x.value || ''))
    pieces.splice(index, 1, before, after)

    const text = joinSmsPieces(pieces)

    const { onChange, onBlur } = this.props
    onChange(text)
    onBlur(text)
  }

  joinPieceWithPreviousOne(e, index) {
    e.preventDefault()

    let pieces = this.allInputs.slice().map(x => x.value || '')
    pieces[index - 1] = `${pieces[index - 1].trim()} ${pieces[index].trim()}`
    pieces.splice(index, 1)

    const text = joinSmsPieces(pieces)

    const { onChange, onBlur } = this.props
    onChange(text)
    onBlur(text)
  }

  getText() {
    return joinSmsPieces(this.allInputs.map(x => (x.value || '')))
  }

  onFocus() {
    const { autocomplete } = this.refs
    if (autocomplete) {
      autocomplete.unhide()
    }
  }

  renderSmsInput(total, index, value, autocompleteComponent) {
    const { id, inputErrors, readOnly } = this.props

    const shouldDisplayErrors = (value == this.props.originalValue) || (limitExceeded(value))

    const maybeInvalidClass = classNames({
      'validate invalid': inputErrors != null && inputErrors.length > 0 && shouldDisplayErrors
    })

    const label = total == 1 ? 'SMS message' : `SMS message (part ${index + 1})`

    const inputComponent = (
      <div>
        <InputWithLabel id={`${id}-${index}`} value={value} readOnly={readOnly} label={label} errors={inputErrors} >
          <input
            type='text'
            onChange={e => this.onChange(e)}
            onKeyUp={e => this.checkKeyUp(e, index)}
            onBlur={e => this.onBlur(e)}
            onFocus={e => this.onFocus()}
            ref={ref => {
              if (ref) {
                this.allInputs.push(ref)
              }
              if (index == 0) {
                this.smsInput = ref
              }
              $(ref).characterCounter()
              $(ref).addClass(maybeInvalidClass)
            }}
            className={maybeInvalidClass}
          />
        </InputWithLabel>
        <CharacterCounter text={value} />
      </div>
    )
    if (total <= 1 || index == 0) {
      return (
        <div className='row' key={index}>
          <div className='col input-field s12'>
            {inputComponent}
            {index == 0 ? autocompleteComponent : null}
          </div>
        </div>
      )
    } else {
      return (
        <div className='row' key={index}>
          <div className='col input-field s11'>
            {inputComponent}
            {index == 0 ? autocompleteComponent : null}
          </div>
          <div className='col s1'>
            <a href='#' onClick={e => this.joinPieceWithPreviousOne(e, index)} style={{position: 'relative', top: 38}}>
              <i className='grey-text material-icons'>highlight_off</i>
            </a>
          </div>
        </div>
      )
    }
  }

  render() {
    const { value, autocomplete, autocompleteGetData, autocompleteOnSelect } = this.props

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

    // We store all inputs in the component, so later we
    // know the whole text by joining the inputs' values
    this.allInputs = []

    const smsPieces = splitSmsText(value)
    const inputs = smsPieces.map((piece, index) => {
      return this.renderSmsInput(smsPieces.length, index, piece, autocompleteComponent)
    })

    return (
      <div>
        {inputs}
      </div>
    )
  }
}

SmsPrompt.propTypes = {
  id: PropTypes.string.isRequired,
  originalValue: PropTypes.string.isRequired,
  value: PropTypes.string.isRequired,
  inputErrors: PropTypes.array,
  onChange: PropTypes.func.isRequired,
  onBlur: PropTypes.func.isRequired,
  readOnly: PropTypes.bool,
  autocomplete: PropTypes.bool.isRequired,
  autocompleteGetData: PropTypes.func,
  autocompleteOnSelect: PropTypes.func}

export default SmsPrompt
