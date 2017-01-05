import React, { Component } from 'react'
import { UntitledIfEmpty } from '.'

export class EditableTitleLabel extends Component {
  static propTypes = {
    onSubmit: React.PropTypes.func.isRequired,
    title: React.PropTypes.string,
    emptyText: React.PropTypes.string,
    entityName: React.PropTypes.string,
    editing: React.PropTypes.bool
  }

  constructor(props) {
    super(props)
    this.state = {
      editing: false
    }
    this.inputRef = null
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
    if (event.key == 'Enter') {
      this.endAndSubmit()
    } else if (event.key == 'Escape') {
      this.endEdit()
    }
  }

  render() {
    const { title, emptyText, entityName } = this.props

    let icon = null
    if (!title || title.trim() == '') {
      icon = <i className='material-icons'>mode_edit</i>
    }

    if (!this.state.editing) {
      return (
        <a className='page-title truncate' onClick={e => this.handleClick(e)}>
          <span><UntitledIfEmpty text={title} emptyText={emptyText} entityName={entityName} /></span>
          {icon}
        </a>
      )
    } else {
      return (
        <input
          type='text'
          ref={node => { this.inputRef = node }}
          autoFocus
          maxLength='255'
          defaultValue={title}
          onKeyDown={e => this.onKeyDown(e)}
          onBlur={e => this.endAndSubmit(e)}
          />
      )
    }
  }
}
