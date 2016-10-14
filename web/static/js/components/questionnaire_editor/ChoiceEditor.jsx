import React, { Component, PropTypes } from 'react'

class ChoiceEditor extends Component {
  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props)
  }

  responseChange(event) {
    event.preventDefault()
    this.setState({ response: event.target.value, sms: this.state.sms })
  }

  smsChange(event) {
    event.preventDefault()
    this.setState({ response: this.state.response, sms: event.target.value })
  }

  componentWillReceiveProps(newProps) {
    this.setState(this.stateFromProps(newProps))
  }

  stateFromProps(props) {
    const { choice } = props
    return { response: choice.value, sms: choice.responses.join(', ') }
  }

  render() {
    const { onChoiceChange, onDelete } = this.props

    return (
      <tr>
        <td>
          <input
            type='text'
            value={this.state.response}
            onChange={e => this.responseChange(e)}
            onBlur={e => onChoiceChange(this.state.response, this.state.sms)} />
        </td>
        <td>
          <input
            type='text'
            value={this.state.sms}
            onChange={e => this.smsChange(e)}
            onBlur={e => onChoiceChange(this.state.response, this.state.sms)} />
        </td>
        <td>
          <a href='#!' onClick={onDelete}><i className='material-icons'>delete</i></a>
        </td>
      </tr>
    )
  }
}

ChoiceEditor.propTypes = {
  onDelete: PropTypes.func,
  onChoiceChange: PropTypes.func,
  choice: PropTypes.object,
  editing: PropTypes.bool
}

export default ChoiceEditor
