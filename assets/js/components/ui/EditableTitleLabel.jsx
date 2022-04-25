import React, { Component, PropTypes } from "react"
import { UntitledIfEmpty } from "."
import classNames from "classnames/bind"

export class EditableTitleLabel extends Component {
  static propTypes = {
    onSubmit: PropTypes.func.isRequired,
    title: PropTypes.string,
    emptyText: PropTypes.string.isRequired,
    editing: PropTypes.bool,
    readOnly: PropTypes.bool,
    inputShort: PropTypes.bool,
    more: PropTypes.node,
  }

  constructor(props) {
    super(props)
    this.state = {
      editing: false,
    }
    this.inputRef = null
  }

  handleClick() {
    if (!this.state.editing && !this.props.readOnly) {
      this.setState({ editing: !this.state.editing })
    }
  }

  endEdit() {
    this.setState({ editing: false })
  }

  endAndSubmit() {
    const { onSubmit } = this.props
    this.endEdit()
    onSubmit(this.inputRef.value)
  }

  onKeyDown(event) {
    if (event.key == "Enter") {
      this.endAndSubmit()
    } else if (event.key == "Escape") {
      this.endEdit()
    }
  }

  render() {
    const { title, emptyText, more } = this.props

    let icon = null
    const iconClasses = this.props.inputShort ? "material-icons smallIcon" : "material-icons"
    if ((!title || title.trim() == "") && !this.props.readOnly) {
      icon = <i className={iconClasses}>mode_edit</i>
    }
    const classes = this.props.inputShort ? "inputShort" : null

    if (!this.state.editing) {
      return (
        <div className="title">
          <a
            className={classNames({
              "page-title": true,
              truncate: title && title.trim() != "",
            })}
            onClick={(e) => this.handleClick(e)}
          >
            <UntitledIfEmpty text={title} emptyText={emptyText} />
            {icon}
          </a>
          {more}
        </div>
      )
    } else {
      return (
        <input
          type="text"
          ref={(node) => {
            this.inputRef = node
          }}
          autoFocus
          maxLength="255"
          defaultValue={title}
          className={classes}
          onKeyDown={(e) => this.onKeyDown(e)}
          onBlur={(e) => this.endAndSubmit(e)}
        />
      )
    }
  }
}
