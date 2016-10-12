import React, { Component } from 'react'

export class EditableTitleLabel extends Component {
  constructor(props) {
    super(props)
    this.state = {
      editing: false
    }
    this.inputRef = null
    this.handleClick = this.handleClick.bind(this)
    this.onKeyDown = this.onKeyDown.bind(this)
    this.endEdit = this.endEdit.bind(this)
    this.endAndSubmit = this.endAndSubmit.bind(this)
  }

  static propTypes = {
    onSubmit: React.PropTypes.func.isRequired,
    title: React.PropTypes.string.isRequired,
    editing: React.PropTypes.bool
  }

  handleClick() {
    if (!this.state.editing) {
      this.setState({editing: !this.state.editing})
    }
  }

  endEdit() {
    this.setState({editing: false})
  }

  endAndSubmit() {
    const { onSubmit } = this.props
    this.endEdit()
    onSubmit(this.inputRef.value)
  }

  onKeyDown(event) {
    if (event.key === 'Enter') {
      this.endAndSubmit()
    } else if (event.key === 'Escape') {
      this.endEdit()
    }
  }

  render() {
    const { title } = this.props
    if (!this.state.editing) {
      return (
        <div onClick={this.handleClick} style={{display: 'inline-block'}}>
          <div style={{display: 'inline-block'}}><a className='breadcrumb'>{title}</a></div>
          <div style={{display: 'inline-block'}}>
            <i className='material-icons' style={{fontSize: '1.5rem', color: '#9e9e9e', paddingLeft: '15px'}}>mode_edit</i>
          </div>
        </div>
      )
    } else {
      return (
        <div
          // className='input-field'
          onClick={this.clickAfuera}
          style={{display: 'inline-block'}}>
          <input
            type='text'
            id='questionnaire_name'
            ref={node => { this.inputRef = node }}
            autoFocus
            defaultValue={title}
            onKeyDown={this.onKeyDown}
            onBlur={this.endAndSubmit}
            />
        </div>
      )
    }
  }
}
