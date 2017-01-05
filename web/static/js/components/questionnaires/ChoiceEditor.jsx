// @flow
import React, { Component } from 'react'
import { UntitledIfEmpty, Tooltip, Autocomplete } from '../ui'
import { connect } from 'react-redux'
import classNames from 'classnames/bind'
import SkipLogic from './SkipLogic'
import { getChoiceResponseSmsJoined, getChoiceResponseIvrJoined } from '../../step'

type Props = {
  onDelete: Function,
  onChoiceChange: Function,
  choice: Choice,
  choiceIndex: number,
  step: Step,
  stepsBefore: Step[],
  stepsAfter: Step[],
  questionnaire: Questionnaire,
  sms: boolean,
  ivr: boolean,
  errors: QuizErrors,
  errorPath: string,
  smsAutocompleteGetData: Function,
  smsAutocompleteOnSelect: Function,
};

type Focus = null | 'response' | 'sms' | 'ivr';

type State = {
  response: string,
  sms: string,
  ivr: string,
  editing: boolean,
  focus: Focus,
  doNotClose: boolean,
  skipLogic: ?string,
  errors: ?QuizErrors,
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
    let newState = this.stateFromProps(newProps)
    this.setState({ ...newState, editing: this.state.editing })
  }

  stateFromProps(props: Props) {
    const { choice } = props
    const lang = props.questionnaire.activeLanguage

    return {
      response: choice.value,
      sms: getChoiceResponseSmsJoined(choice, lang),
      ivr: getChoiceResponseIvrJoined(choice),
      skipLogic: choice.skipLogic
    }
  }

  enterEditMode(event: Event, focus: Focus) {
    event.preventDefault()
    this.setState({
      ...this.state,
      editing: true,
      focus: focus
    })
  }

  exitEditMode(autoComplete: boolean = false) {
    let autocomplete = this.refs.autocomplete
    if (autocomplete && autocomplete.clickingAutocomplete) return

    const { onChoiceChange } = this.props
    if (this.state.doNotClose) {
      this.state.doNotClose = false
      if (autoComplete) {
        onChoiceChange(this.state.response, this.state.sms, this.state.ivr, this.state.skipLogic, true)
      }
    } else {
      this.setState({
        ...this.state,
        editing: false
      }, () => {
        onChoiceChange(this.state.response, this.state.sms, this.state.ivr, this.state.skipLogic, autoComplete)
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

  skipLogicChange(skipOption: ?string) {
    const { onChoiceChange } = this.props
    this.setState({
      ...this.state,
      skipLogic: skipOption
    }, () => {
      onChoiceChange(this.state.response, this.state.sms, this.state.ivr, this.state.skipLogic)
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

  cell(value: string, emptyValue: string, errors: string[], shouldDisplay: boolean, onClick: Function) {
    const tooltip = (errors || [value]).join(', ')
    const elem = shouldDisplay
      ? <div>
        <UntitledIfEmpty
          text={value}
          emptyText={emptyValue}
          className={classNames({'basic-error tooltip-error': errors})} />
      </div>
    : null

    return shouldDisplay
    ? <td onClick={onClick}>
      {this.maybeTooltip(errors, elem, tooltip)}
    </td> : null
  }

  render() {
    const { onDelete, stepsBefore, stepsAfter, sms, ivr, errors, errorPath,
      smsAutocompleteGetData, smsAutocompleteOnSelect } = this.props

    let skipLogicInput =
      <td>
        <SkipLogic
          onChange={skipOption => this.skipLogicChange(skipOption)}
          value={this.state.skipLogic}
          stepsAfter={stepsAfter}
          stepsBefore={stepsBefore}
          />
      </td>

    if (this.state.editing) {
      return (
        <tr>
          <td onMouseDown={e => this.setDoNotClose('response')}>
            <input
              type='text'
              placeholder='Response'
              value={this.state.response}
              autoFocus={this.state.focus == 'response'}
              onChange={e => this.responseChange(e)}
              onBlur={e => this.autoComplete(e)}
              onKeyDown={(e: Event) => this.onKeyDown(e, 'sms', true)} />
          </td>
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
          {skipLogicInput}
          <td>
            <a href='#!' onFocus={e => this.exitEditMode()} onClick={onDelete}><i className='material-icons grey-text'>delete</i></a>
          </td>
        </tr>)
    } else {
      let responseErrors = errors[`${errorPath}.value`]
      let smsErrors = errors[`${errorPath}.sms`]
      let ivrErrors = errors[`${errorPath}.ivr`]

      return (
        <tr>
          {this.cell(this.state.response, 'No response', responseErrors, true, e => this.enterEditMode(e, 'response'))}
          {this.cell(this.state.sms, 'No SMS', smsErrors, sms, e => this.enterEditMode(e, 'sms'))}
          {this.cell(this.state.ivr, 'No IVR', ivrErrors, ivr, e => this.enterEditMode(e, 'ivr'))}
          {skipLogicInput}
          <td>
            <a href='#!' onClick={onDelete}><i className='material-icons grey-text'>delete</i></a>
          </td>
        </tr>
      )
    }
  }
}

const mapStateToProps = (state, ownProps) => ({
})

export default connect(mapStateToProps)(ChoiceEditor)
