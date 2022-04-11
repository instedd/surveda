import React, { Component, PropTypes } from "react"

class StyleButton extends Component {
  constructor(props) {
    super(props)
    this.onToggle = (e) => {
      e.preventDefault()
      this.props.onToggle(this.props.style)
    }
  }

  render() {
    let className = "material-icons"
    if (!this.props.active) {
      className += " grey-text"
    }

    return (
      <span
        style={{ cursor: "pointer" }}
        title={this.props.label}
        className={className}
        onMouseDown={this.onToggle}
      >
        {this.props.icon}
      </span>
    )
  }
}

StyleButton.propTypes = {
  onToggle: PropTypes.func,
  active: PropTypes.bool,
  label: PropTypes.string,
  icon: PropTypes.string,
  style: PropTypes.string,
}

export default StyleButton
