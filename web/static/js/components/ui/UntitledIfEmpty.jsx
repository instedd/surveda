import React, { PropTypes, Component } from 'react'

export const defaultIfEmpty = (text, defaultText) => (!text || text.trim() == '') ? defaultText : text

export class UntitledIfEmpty extends Component {
  render() {
    const { text, emptyText, className } = this.props

    if (!text || text.trim() == '') {
      return <em className={className}>{emptyText}</em>
    } else {
      return <span className={className}>{text}</span>
    }
  }
}

UntitledIfEmpty.propTypes = {
  text: PropTypes.string,
  emptyText: PropTypes.string.isRequired,
  className: PropTypes.string,
  entityName: PropTypes.string
}
