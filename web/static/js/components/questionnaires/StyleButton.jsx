import React, { Component, PropTypes } from 'react'

class StyleButton extends Component {
  constructor(props) {
    super(props)
    this.onToggle = (e) => {
      e.preventDefault()
      this.props.onToggle(this.props.style)
    }
  }

  render() {
    let className = 'RichEditor-styleButton'
    if (this.props.active) {
      className += ' RichEditor-activeButton'
    }

    return (
      <span className={className} onMouseDown={this.onToggle}>
        {this.props.label}
      </span>
    )
  }
}

StyleButton.propTypes = {
  onToggle: PropTypes.func,
  active: PropTypes.bool,
  label: PropTypes.string,
  style: PropTypes.object
}

export default StyleButton
