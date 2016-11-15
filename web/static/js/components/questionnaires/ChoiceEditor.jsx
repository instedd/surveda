import React, { Component, PropTypes } from 'react'
import { UntitledIfEmpty } from '../ui'
import { Input } from 'react-materialize'

class ChoiceEditor extends Component {
  constructor(props) {
    super(props)
    this.state = Object.assign({}, this.stateFromProps(props), { editing: false, doNotClose: false })
  }

  responseChange(event) {
    event.preventDefault()
    this.setState({
      ...this.state,
      response: event.target.value
    })
  }

  smsChange(event) {
    event.preventDefault()
    this.setState({
      ...this.state,
      sms: event.target.value
    })
  }

  ivrChange(event) {
    event.preventDefault()
    this.setState({
      ...this.state,
      ivr: event.target.value
    })
  }

  componentWillReceiveProps(newProps) {
    let newState = this.stateFromProps(newProps)
    this.setState(Object.assign({}, newState, { editing: this.state.editing }))
  }

  stateFromProps(props) {
    const { choice } = props
    return {
      response: choice.value,
      sms: choice.responses.sms.join(', '),
      ivr: choice.responses.ivr.join(', '),
      skipLogic: choice.skipLogic,
      errors: choice.errors
    }
  }

  enterEditMode(event, focus) {
    event.preventDefault()
    this.setState({
      ...this.state,
      editing: true,
      focus: focus
    })
  }

  exitEditMode(autoComplete = false) {
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

  autoComplete(event) {
    this.exitEditMode(true)
  }

  setDoNotClose(focus) {
    if (this.state.focus != focus) {
      this.state.doNotClose = true
      this.state.focus = focus
    }
  }

  onKeyDown(event, autoComplete = false) {
    if (event.key == 'Enter') {
      event.preventDefault()
      this.exitEditMode(autoComplete)
    } else if (event.key == 'Tab') {
      this.setDoNotClose()
    }
  }

  skipLogicChange(event) {
    const { onChoiceChange } = this.props
    this.setState({
      ...this.state,
      skipLogic: event.target.value == '' ? null : event.target.value
    })
    onChoiceChange(this.state.response, this.state.sms, this.state.ivr, this.state.skipLogic)
  }

  render() {
    const { onDelete, skipOptions, sms, ivr } = this.props

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
              onKeyDown={e => this.onKeyDown(e, true)} />
          </td>
          { sms
          ? <td onMouseDown={e => this.setDoNotClose('sms')}>
            <input
              type='text'
              placeholder='SMS'
              value={this.state.sms}
              autoFocus={this.state.focus == 'sms'}
              onChange={e => this.smsChange(e)}
              onBlur={e => this.exitEditMode()}
              onKeyDown={e => this.onKeyDown(e)} />
          </td> : null
          }
          { ivr
          ? <td onMouseDown={e => this.setDoNotClose('ivr')}>
            <input
              type='text'
              placeholder='IVR'
              value={this.state.ivr}
              autoFocus={this.state.focus == 'ivr'}
              onChange={e => this.ivrChange(e)}
              onBlur={e => this.exitEditMode()}
              onKeyDown={e => this.onKeyDown(e)} />
          </td> : null
          }
          {skipLogicInput}
          <td>
            <a href='#!' onFocus={e => this.exitEditMode()} onClick={onDelete}><i className='material-icons grey-text'>delete</i></a>
          </td>
        </tr>)
    } else {
      return (
        <tr>
          <td onClick={e => this.enterEditMode(e, 'response')}>
            <UntitledIfEmpty text={this.state.response} emptyText='No response' />
          </td>
          { sms
          ? <td onClick={e => this.enterEditMode(e, 'sms')}>
            <UntitledIfEmpty text={this.state.sms} emptyText='No SMS' />
          </td> : null
          }
          { ivr
          ? <td onClick={e => this.enterEditMode(e, 'ivr')} className={this.state.errors && this.state.errors.responses.ivr ? 'basic-error' : ''}>
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
  choice: PropTypes.object,
  skipOptions: PropTypes.array,
  sms: PropTypes.bool,
  ivr: PropTypes.bool
}

export default ChoiceEditor
