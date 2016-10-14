import React, { Component, PropTypes } from 'react'

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
    return { response: choice.value, sms: choice.responses.join(', ') }
  }

  enterEditMode(event) {
    event.preventDefault()
    this.setState({
      ...this.state,
      editing: true
    })
  }

  exitEditMode() {
    const { onChoiceChange } = this.props

    this.setState({
      ...this.state,
      editing: false
    }, () => {
      onChoiceChange(this.state.response, this.state.sms)
    })
  }

  onKeyDown(event) {
    if (event.key === 'Enter') {
      event.preventDefault()
      this.exitEditMode()
    }
  }

  render() {
    const { onChoiceChange, onDelete } = this.props
    if (this.state.editing) {
      return (
        <tr>
          <td>
            <input
              type='text'
              value={this.state.response}
              onChange={e => this.responseChange(e)}
              onBlur={e => onChoiceChange(this.state.response, this.state.sms)}
              onKeyDown={e => this.onKeyDown(e)} />
          </td>
          <td>
            <input
              type='text'
              value={this.state.sms}
              onChange={e => this.smsChange(e)}
              onBlur={e => onChoiceChange(this.state.response, this.state.sms)}
              onKeyDown={e => this.onKeyDown(e)} />
          </td>
          <td>
            <a href='#!' onClick={onDelete}><i className='material-icons'>delete</i></a>
          </td>
        </tr>)
    } else {
      return (
        <tr onClick={e => this.enterEditMode(e)} >
          <td>
            {this.state.response}
          </td>
          <td>
            {this.state.sms}
          </td>
          <td>
            <a href='#!' onClick={onDelete}><i className='material-icons'>delete</i></a>
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
