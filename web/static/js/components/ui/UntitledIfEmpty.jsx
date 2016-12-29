import React, { PropTypes, Component } from 'react'

export class UntitledIfEmpty extends Component {
  render() {
    const { text, emptyText = 'Untitled', className } = this.props

    if (!text || text.trim() == '') {
      return <em className={className}>{emptyText}</em>
    } else {
      return <span className={className}>{text}</span>
    }
  }
}

UntitledIfEmpty.propTypes = {
  text: PropTypes.string,
  emptyText: PropTypes.string,
  className: PropTypes.string
}
