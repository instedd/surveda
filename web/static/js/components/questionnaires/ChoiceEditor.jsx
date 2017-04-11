// @flow
import React, { Component } from 'react'
import { UntitledIfEmpty, Tooltip, Autocomplete } from '../ui'
import classNames from 'classnames/bind'
import SkipLogic from './SkipLogic'
import { getChoiceResponseSmsJoined, getChoiceResponseIvrJoined, getChoiceResponseMobileWebJoined } from '../../step'
import { choiceValuePath, choiceSmsResponsePath, choiceIvrResponsePath, choiceMobileWebResponsePath } from '../../questionnaireErrors'
import propsAreEqual from '../../propsAreEqual'

type Props = {
  onDelete: Function,
  onChoiceChange: Function,
  choice: Choice,
  choiceIndex: any,
  readOnly: boolean,
  stepIndex: number,
  stepsBefore: Step[],
  stepsAfter: Step[],
  lang: string,
  sms: boolean,
  mobileweb: boolean,
  ivr: boolean,
  errors: Errors,
  smsAutocompleteGetData: Function,
  smsAutocompleteOnSelect: Function,
};

type Focus = null | 'response' | 'sms' | 'ivr' | 'mobileweb';

type State = {
  response: string,
  sms: string,
  ivr: string,
  mobileweb: string,
  editing: boolean,
  focus: Focus,
  doNotClose: boolean,
  skipLogic: ?string,
  errors: ?Errors,
};

class ChoiceEditor extends Component {
  props: Props
  state: State

  constructor(props: Props) {
    super(props)
    this.state = { ...this.stateFromProps(props), editing: false, doNotClose: false, focus: null, errors: null }
  }

  responseChange(event: Event) {
    event.preventDefault()
    if (event.target instanceof HTMLInputElement) {
      this.setState({
        ...this.state,
        response: event.target.value
      })
    }
  }

  smsChange(event: ?Event, sms: string) {
    if (event) event.preventDefault()
    this.setState({
      ...this.state,
      sms
    })
  }

  mobilewebChange(event: ?Event, mobileweb: string) {
    if (event) event.preventDefault()
    this.setState({
      ...this.state,
      mobileweb
    })
  }

  ivrChange(event: Event) {
    event.preventDefault()
    if (event.target instanceof HTMLInputElement) {
      this.setState({
        ...this.state,
        ivr: event.target.value
      })
    }
  }

  componentWillReceiveProps(newProps: Props) {
    if (propsAreEqual(this.props, newProps)) return

    let newState = this.stateFromProps(newProps)
    this.setState({ ...newState, editing: this.state.editing })
  }

  stateFromProps(props: Props) {
    const { choice, lang } = props

    return {
      response: choice.value,
      sms: getChoiceResponseSmsJoined(choice, lang),
      ivr: getChoiceResponseIvrJoined(choice),
      mobileweb: getChoiceResponseMobileWebJoined(choice, lang),
      skipLogic: choice.skipLogic
    }
  }

  enterEditMode(event: Event, focus: Focus) {
    event.preventDefault()
    const {readOnly} = this.props
    if (!readOnly) {
      this.setState({
        ...this.state,
        editing: true,
        focus: focus
      })
    }
  }

  exitEditMode(autoComplete: boolean = false) {
    let autocomplete = this.refs.autocomplete
    if (autocomplete && autocomplete.clickingAutocomplete) return

    const { onChoiceChange } = this.props
    if (this.state.doNotClose) {
      this.state.doNotClose = false
      if (autoComplete) {
        onChoiceChange(this.state.response, this.state.sms, this.state.ivr, this.state.mobileweb, this.state.skipLogic, true)
      }
    } else {
      this.setState({
        ...this.state,
        editing: false
      }, () => {
        onChoiceChange(this.state.response, this.state.sms, this.state.ivr, this.state.mobileweb, this.state.skipLogic, autoComplete)
      })
    }
  }

  autoComplete(event: Event) {
    this.exitEditMode(true)
  }

  setDoNotClose(focus: Focus) {
    if (this.state.focus != focus) {
      this.state.doNotClose = true
      this.state.focus = focus
    }
  }

  onKeyDown(event: Event, focus: Focus, autoComplete: boolean = false) {
    if (event.key == 'Enter') {
      event.preventDefault()
      this.exitEditMode(autoComplete)
    } else if (event.key == 'Tab') {
      this.setDoNotClose(focus)
    }
  }

  smsCheckEmptyString(event: Event) {
    // This is due to a materialize css bug. Analogous to SmsPrompt
    if (!event.target.value) {
      this.smsChange(event, '')
    }
  }

  skipLogicChange(skipOption: ?string) {
    const { onChoiceChange } = this.props
    this.setState({
      ...this.state,
      skipLogic: skipOption
    }, () => {
      onChoiceChange(this.state.response, this.state.sms, this.state.ivr, this.state.mobileweb, this.state.skipLogic)
    })
  }

  maybeTooltip(shouldWrap: any, elem: any, tooltipText: string) {
    if (shouldWrap) {
      return (
        <Tooltip text={tooltipText} position='bottom' className='error'>
          {elem}
        </Tooltip>
      )
    } else {
      return elem
    }
  }

  cell(value: string, errors: string[], shouldDisplay: boolean, onClick: Function) {
    const tooltip = (errors || [value]).join(', ')
    const emptyValue = !value || value.trim().length == 0
    const className = emptyValue ? 'tooltip-error' : 'basic-error'

    const elem = shouldDisplay
      ? <div>
        <UntitledIfEmpty
          text={value}
          emptyText={'\u00a0'}
          className={classNames({[className]: errors})} />
      </div>
    : null

    return shouldDisplay
    ? <td onClick={onClick}>
      {this.maybeTooltip(errors, elem, tooltip)}
    </td> : null
  }

  render() {
    const { onDelete, stepIndex, stepsBefore, stepsAfter, readOnly, choiceIndex, sms, ivr, mobileweb, errors, lang, smsAutocompleteGetData, smsAutocompleteOnSelect } = this.props

    const isRefusal = choiceIndex == 'refusal'

    let skipLogicInput =
      <td>
        <SkipLogic
          onChange={skipOption => this.skipLogicChange(skipOption)}
          readOnly={readOnly}
          value={this.state.skipLogic}
          stepsAfter={stepsAfter}
          stepsBefore={stepsBefore}
          />
      </td>

    if (this.state.editing) {
      return (
        <tr>
          {!isRefusal
          ? <td onMouseDown={e => this.setDoNotClose('response')}>
            <input
              type='text'
              placeholder='Response'
              value={this.state.response}
              autoFocus={this.state.focus == 'response'}
              onChange={e => this.responseChange(e)}
              onBlur={e => this.autoComplete(e)}
              onKeyDown={(e: Event) => this.onKeyDown(e, 'sms', true)} />
          </td>
          : null }
          { sms
          ? <td onMouseDown={e => this.setDoNotClose('sms')}>
            <input
              type='text'
              ref='smsInput'
              placeholder='Valid entries'
              value={this.state.sms}
              autoFocus={this.state.focus == 'sms'}
              onChange={e => this.smsChange(e, e.target.value)}
              onBlur={e => this.exitEditMode()}
              onKeyUp={e => this.smsCheckEmptyString(e)}
              onKeyDown={e => this.onKeyDown(e, 'ivr')} />
            <Autocomplete
              getInput={() => this.refs.smsInput}
              getData={(value, callback) => smsAutocompleteGetData(value, callback)}
              onSelect={(item) => smsAutocompleteOnSelect(item)}
              ref='autocomplete'
              />
          </td> : null
          }
          { ivr
          ? <td onMouseDown={e => this.setDoNotClose('ivr')}>
            <input
              type='text'
              placeholder='Valid entries'
              value={this.state.ivr}
              autoFocus={this.state.focus == 'ivr'}
              onChange={e => this.ivrChange(e)}
              onBlur={e => this.exitEditMode()}
              onKeyDown={e => this.onKeyDown(e, 'ivr')} />
          </td> : null
          }
          {
            mobileweb
          ? <td onMouseDown={e => this.setDoNotClose('mobileweb')}>
            <input
              type='text'
              placeholder='Valid entries'
              value={this.state.mobileweb}
              autoFocus={this.state.focus == 'mobileweb'}
              onChange={e => this.mobilewebChange(e, e.target.value)}
              onBlur={e => this.exitEditMode()}
              onKeyDown={e => this.onKeyDown(e, 'ivr')} />
          </td> : null
          }
          {skipLogicInput}
          { (!isRefusal)
          ? <td>
            <a href='#!' onFocus={e => this.exitEditMode()} onClick={onDelete}><i className='material-icons grey-text'>delete</i></a>
          </td> : null
          }
        </tr>)
    } else {
      let responseErrors = !isRefusal ? errors[choiceValuePath(stepIndex, choiceIndex)] : []
      let smsErrors = errors[choiceSmsResponsePath(stepIndex, choiceIndex, lang)]
      let ivrErrors = errors[choiceIvrResponsePath(stepIndex, choiceIndex)]
      let mobilewebErrors = errors[choiceMobileWebResponsePath(stepIndex, choiceIndex, lang)]

      return (
        <tr>
          {!isRefusal
          ? this.cell(this.state.response, responseErrors, true, e => this.enterEditMode(e, 'response'))
          : null
          }
          {this.cell(this.state.sms, smsErrors, sms, e => this.enterEditMode(e, 'sms'))}
          {this.cell(this.state.ivr, ivrErrors, ivr, e => this.enterEditMode(e, 'ivr'))}
          {this.cell(this.state.mobileweb, mobilewebErrors, mobileweb, e => this.enterEditMode(e, 'mobileweb'))}
          {skipLogicInput}
          { readOnly || isRefusal ? <td />
            : <td>
              <a href='#!' onClick={onDelete}><i className='material-icons grey-text'>delete</i></a>
            </td>
          }
        </tr>
      )
    }
  }
}

export default ChoiceEditor
