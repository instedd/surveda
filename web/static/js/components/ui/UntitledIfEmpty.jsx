import React, { PropTypes, Component } from 'react'

export class UntitledIfEmpty extends Component {
  render() {
    const { text, emptyText = 'Untitled', className, entityName } = this.props

    let completeEmptyText = null

    if (emptyText == 'Untitled' && entityName) {
      completeEmptyText = `${emptyText} ${entityName}`
    } else {
      completeEmptyText = emptyText
    }

    if (!text || text.trim() == '') {
      return <em className={className}>{completeEmptyText}</em>
    } else {
      return <span className={className}>{text}</span>
    }
  }
}

UntitledIfEmpty.propTypes = {
  text: PropTypes.string,
  emptyText: PropTypes.string,
  className: PropTypes.string,
  entityName: PropTypes.string
}
