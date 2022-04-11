import React, { Component, PropTypes } from "react"
import { UntitledIfEmpty } from "."
import classNames from "classnames/bind"

export class EditableDescriptionLabel extends Component {
  static propTypes = {
    description: PropTypes.string,
    emptyText: PropTypes.string.isRequired,
    onSubmit: PropTypes.func.isRequired,
    readOnly: PropTypes.bool,
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
    const { description, emptyText } = this.props
    if (!this.state.editing) {
      return (
        <div className="description">
          <a
            className={classNames({
              "page-description": true,
              truncate: description && description.trim() != "",
            })}
            onClick={(e) => this.handleClick(e)}
          >
            <UntitledIfEmpty text={description} emptyText={emptyText} />
          </a>
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
          defaultValue={description}
          onKeyDown={(e) => this.onKeyDown(e)}
          onBlur={(e) => this.endAndSubmit(e)}
        />
      )
    }
  }
}
