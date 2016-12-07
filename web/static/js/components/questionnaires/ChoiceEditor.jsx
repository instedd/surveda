// @flow
import React, { Component, PropTypes } from 'react'
import { UntitledIfEmpty } from '../ui'
import { Input } from 'react-materialize'
import classNames from 'classnames/bind'

type SkipOption = {
  id: string,
  title: string
};

type Props = {
  onDelete: Function,
  onChoiceChange: Function,
  choice: Choice,
  skipOptions: SkipOption[],
  questionnaire: Questionnaire,
  saving: bool,
  sms: boolean,
  ivr: boolean,
  errors: any,
  errorPath: string,
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
  errors: ?any,
  saving: bool,
};

class ChoiceEditor extends Component {
  props: Props
  state: State

  constructor(props: Props) {
    super(props)
    this.state = { ...this.stateFromProps(props), editing: false, saving: false, doNotClose: false, focus: null, errors: null }
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

  smsChange(event: Event) {
    event.preventDefault()
    if (event.target instanceof HTMLInputElement) {
      this.setState({
        ...this.state,
        sms: event.target.value
      })
    }
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
    // If we just went from "saving" to "saved", don't
    // override state because it might override data
    // of an input the user is editing
    if (this.state.saving && !newProps.saving) {
      return
    }

    let newState = this.stateFromProps(newProps)
    this.setState({ ...newState, editing: this.state.editing, saving: newProps.saving })
  }

  stateFromProps(props: Props) {
    const { choice } = props
    const lang = props.questionnaire.defaultLanguage

    return {
      response: choice.value,
      sms: ((choice.responses[lang] || {}).sms || []).join(', '),
      ivr: ((choice.responses[lang] || {}).ivr || []).join(', '),
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

  skipLogicChange(event: Event) {
    const { onChoiceChange } = this.props
    if (event.target instanceof HTMLSelectElement) {
      this.setState({
        ...this.state,
        skipLogic: event.target.value == '' ? null : event.target.value
      })
      onChoiceChange(this.state.response, this.state.sms, this.state.ivr, this.state.skipLogic)
    }
  }

  render() {
    const { onDelete, skipOptions, sms, ivr, errors, errorPath } = this.props

    let skipLogicInput = <td>
      <Input s={12} type='select'
        onChange={e => this.skipLogicChange(e)}
        defaultValue={this.state.skipLogic}
        >
        { skipOptions.map((option) =>
          <option key={option.id} id={option.id} name={option.title} value={option.id} >
            {option.title == '' ? 'Untitled' : option.title }
          </option>
        )}
      </Input>
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
              placeholder='Valid entries'
              value={this.state.sms}
              autoFocus={this.state.focus == 'sms'}
              onChange={e => this.smsChange(e)}
              onBlur={e => this.exitEditMode()}
              onKeyDown={e => this.onKeyDown(e, 'ivr')} />
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
      // TODO: these should probably be shown all the time, not only when the values are not empty
      let responseErrors = this.state.response && this.state.response != '' && errors[`${errorPath}.value`]
      let smsErrors = this.state.sms && this.state.sms != '' && errors[`${errorPath}.sms`]
      let ivrErrors = this.state.ivr && this.state.ivr != '' && errors[`${errorPath}.ivr`]

      return (
        <tr>
          <td onClick={e => this.enterEditMode(e, 'response')} className={classNames({'basic-error': responseErrors})}>
            <UntitledIfEmpty text={this.state.response} emptyText='No response' />
          </td>
          { sms
          ? <td onClick={e => this.enterEditMode(e, 'sms')} className={classNames({'basic-error': smsErrors})}>
            <UntitledIfEmpty text={this.state.sms} emptyText='No SMS' />
          </td> : null
          }
          { ivr
          ? <td onClick={e => this.enterEditMode(e, 'ivr')} className={classNames({'basic-error': ivrErrors})}>
            <UntitledIfEmpty text={this.state.ivr} emptyText='No IVR' />
          </td> : null
          }
          {skipLogicInput}
          <td>
            <a href='#!' onClick={onDelete}><i className='material-icons grey-text'>delete</i></a>
          </td>
        </tr>
      )
    }
  }
}

ChoiceEditor.propTypes = {
  onDelete: PropTypes.func,
  onChoiceChange: PropTypes.func,
  questionnaire: PropTypes.object,
  saving: PropTypes.bool,
  choice: PropTypes.object,
  skipOptions: PropTypes.array,
  sms: PropTypes.bool,
  ivr: PropTypes.bool,
  errors: PropTypes.object.isRequired,
  errorPath: PropTypes.string.isRequired
}

export default ChoiceEditor
