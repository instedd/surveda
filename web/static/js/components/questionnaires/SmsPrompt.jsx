import React, { Component, PropTypes } from 'react'
import Draft from './Draft'
import { splitSmsText, joinSmsPieces } from '../../step'
import {limitExceeded} from '../../characterCounter'
import map from 'lodash/map'
import { translate } from 'react-i18next'

const k = (...args: any) => args

class SmsPrompt extends Component {
  onBlur() {
    let autocomplete = this.refs.autocomplete
    if (autocomplete) {
      if (autocomplete.clickingAutocomplete) return
      autocomplete.hide()
    }

    const { onBlur } = this.props
    onBlur(this.getText())
  }

  splitPiece(caretIndex, index) {
    let value = this.allInputs[index].getText()
    let before = value.slice(0, caretIndex)
    let after = value.slice(caretIndex)

    let pieces = this.allInputs.map(x => x.getText())
    pieces.splice(index, 1, before, after)

    const text = joinSmsPieces(pieces)

    const { onBlur } = this.props
    onBlur(text)
  }

  joinPieceWithPreviousOne(e, index) {
    e.preventDefault()

    let pieces = this.allInputs.slice().map(x => x.getText())
    pieces[index - 1] = `${pieces[index - 1].trim()} ${pieces[index].trim()}`
    pieces.splice(index, 1)

    const text = joinSmsPieces(pieces)

    const { onBlur } = this.props
    onBlur(text)
  }

  getText() {
    return joinSmsPieces(this.allInputs.map(x => (x.getText() || '')))
  }

  renderSmsInput(total, index, value) {
    let { inputErrors, readOnly, fixedEndLength, label, t } = this.props

    const shouldDisplayErrors = value == this.props.originalValue

    let textBelow = ''
    if (limitExceeded(value)) {
      textBelow = k('Use SHIFT+ENTER to split in multiple parts')
    }

    if (!label) label = t('SMS message')

    const labelComponent = total == 1 ? label : `${label} (part ${index + 1})`
    const last = index + 1 == total
    const fixedLength = last ? fixedEndLength : null

    let autocompleteProps = {}
    if (index == 0) {
      autocompleteProps = {
        autocomplete: this.props.autocomplete,
        autocompleteGetData: this.props.autocompleteGetData,
        autocompleteOnSelect: this.props.autocompleteOnSelect
      }
    }

    const inputComponent = (
      <div>
        <Draft
          label={labelComponent}
          value={value}
          readOnly={readOnly}
          errors={shouldDisplayErrors && map(inputErrors, (error) => t(...error))}
          textBelow={textBelow}
          onSplit={caretIndex => this.splitPiece(caretIndex, index)}
          onBlur={e => this.onBlur()}
          characterCounter
          characterCounterFixedLength={fixedLength}
          plainText
          ref={ref => { if (ref) { this.allInputs.push(ref) } }}
          {...autocompleteProps}
          />
      </div>
    )
    if (total <= 1 || index == 0) {
      return (
        <div className='row' key={index}>
          <div className='col s12'>
            {inputComponent}
          </div>
        </div>
      )
    } else {
      return (
        <div className='row' key={index}>
          <div className='col s11'>
            {inputComponent}
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
    const { value } = this.props

    // We store all inputs in the component, so later we
    // know the whole text by joining the inputs' values
    this.allInputs = []

    const smsPieces = splitSmsText(value)
    const inputs = smsPieces.map((piece, index) => {
      return this.renderSmsInput(smsPieces.length, index, piece)
    })

    return (
      <div>
        {inputs}
      </div>
    )
  }
}

SmsPrompt.propTypes = {
  t: PropTypes.func,
  id: PropTypes.string.isRequired,
  label: PropTypes.string,
  originalValue: PropTypes.string.isRequired,
  value: PropTypes.string.isRequired,
  inputErrors: PropTypes.array,
  onBlur: PropTypes.func.isRequired,
  readOnly: PropTypes.bool,
  fixedEndLength: PropTypes.number,
  autocomplete: PropTypes.bool,
  autocompleteGetData: PropTypes.func,
  autocompleteOnSelect: PropTypes.func}

export default translate()(SmsPrompt)
