import React, { Component, PropTypes } from 'react'
import { UntitledIfEmpty } from '../ui'

class ChoiceEditor extends Component {
  constructor(props) {
    super(props)
    this.state = Object.assign({}, this.stateFromProps(props), { editing: false })
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

  componentWillReceiveProps(newProps) {
    let newState = this.stateFromProps(newProps)
    this.setState(Object.assign({}, newState, { editing: this.state.editing }))
  }

  stateFromProps(props) {
    const { choice } = props
    return { response: choice.value, sms: choice.responses.sms.join(', ') }
  }

  enterEditMode(event, focus) {
    event.preventDefault()
    this.setState({
      ...this.state,
      editing: true,
      focus: focus
    })
  }

  exitEditMode() {
    const { onChoiceChange } = this.props
    if (this.state.doNotClose) {
      this.state.doNotClose = false
    } else {
      this.setState({
        ...this.state,
        editing: false
      }, () => {
        onChoiceChange(this.state.response, this.state.sms)
      })
    }
  }

  setDoNotClose() {
    this.state.doNotClose = true
  }

  onKeyDown(event) {
    if (event.key === 'Enter') {
      event.preventDefault()
      this.exitEditMode()
    } else if (event.key === 'Tab') {
      this.setDoNotClose()
    }
  }

  render() {
    const { onDelete } = this.props
    if (this.state.editing) {
      return (
        <tr>
          <td>
            <input
              type='text'
              placeholder='Response'
              value={this.state.response.sms}
              autoFocus={this.state.focus === 'response'}
              onChange={e => this.responseChange(e)}
              onMouseDown={e => this.setDoNotClose()}
              onBlur={e => this.exitEditMode()}
              onKeyDown={e => this.onKeyDown(e)} />
          </td>
          <td>
            <input
              type='text'
              placeholder='SMS'
              value={this.state.sms}
              autoFocus={this.state.focus === 'sms'}
              onChange={e => this.smsChange(e)}
              onMouseDown={e => this.setDoNotClose()}
              onBlur={e => this.exitEditMode()}
              onKeyDown={e => this.onKeyDown(e)} />
          </td>
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
          <td onClick={e => this.enterEditMode(e, 'sms')}>
            <UntitledIfEmpty text={this.state.sms} emptyText='No SMS' />
          </td>
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
  choice: PropTypes.object
}

export default ChoiceEditor
