import React, { Component, PropTypes } from "react"
import Draft from "./Draft"
import { splitSmsText, joinSmsPieces } from "../../step"
import { limitExceeded } from "../../characterCounter"
import map from "lodash/map"
import { translate } from "react-i18next"

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

    let pieces = this.allInputs.map((x) => x.getText())
    pieces.splice(index, 1, before, after)

    const text = joinSmsPieces(pieces)

    const { onBlur } = this.props
    onBlur(text)
  }

  joinPieceWithPreviousOne(e, index) {
    e.preventDefault()

    let pieces = this.allInputs.slice().map((x) => x.getText())
    pieces[index - 1] = `${pieces[index - 1].trim()} ${pieces[index].trim()}`
    pieces.splice(index, 1)

    const text = joinSmsPieces(pieces)

    const { onBlur } = this.props
    onBlur(text)
  }

  getText() {
    return joinSmsPieces(this.allInputs.map((x) => x.getText() || ""))
  }

  filterErrorsForPart(errors, index) {
    const partErrorPrefix = `[${index}]`
    return errors &&
      errors
      .flat()
      // We are interested only in the errors that
      // match with the sms part index
      .filter(error => error.startsWith(partErrorPrefix))
      .map(error => {
        // We remove the part prefix
        const errorMessage = error.split(partErrorPrefix)[1]
        return [errorMessage]
      })
  }

  renderSmsInput(total, index, value) {
    let { inputErrors, readOnly, fixedEndLength, label, t } = this.props
    const last = index + 1 == total
    const first = index == 0
    const textBelow = limitExceeded(value) ? k("Use SHIFT+ENTER to split in multiple parts") : ""

    if (!label) label = t("SMS message")

    if (total > 1){
      label = `${label} (part ${index + 1})`
      inputErrors = this.filterErrorsForPart(inputErrors, index)
    }

    let autocompleteProps = {}
    if (first) {
      autocompleteProps = {
        autocomplete: this.props.autocomplete,
        autocompleteGetData: this.props.autocompleteGetData,
        autocompleteOnSelect: this.props.autocompleteOnSelect,
      }
    }

    const inputComponent = (
      <div>
        <Draft
          label={label}
          value={value}
          readOnly={readOnly}
          errors={map(inputErrors, (error) => t(...error))}
          textBelow={textBelow}
          onSplit={(caretIndex) => this.splitPiece(caretIndex, index)}
          onBlur={(e) => this.onBlur()}
          characterCounter
          characterCounterFixedLength={last ? fixedEndLength : null}
          plainText
          ref={(ref) => {
            if (ref) {
              this.allInputs.push(ref)
            }
          }}
          {...autocompleteProps}
        />
      </div>
    )
    if (index == 0) {
      return (
        <div className="row" key={index}>
          <div className="col s12">{inputComponent}</div>
        </div>
      )
    } else {
      return (
        <div className="row" key={index}>
          <div className="col s11">{inputComponent}</div>
          <div className="col s1">
            <a
              href="#"
              onClick={(e) => this.joinPieceWithPreviousOne(e, index)}
              style={{ position: "relative", top: 38 }}
            >
              <i className="grey-text material-icons">highlight_off</i>
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

    return <div>{inputs}</div>
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
  autocompleteOnSelect: PropTypes.func,
}

export default translate()(SmsPrompt)
