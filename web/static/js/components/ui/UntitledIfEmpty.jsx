import React, { PropTypes } from 'react'

export const UntitledIfEmpty = ({ text, emptyText = 'Untitled', className }) => {
  if (!text || text.trim() == '') {
    return <em className={className}>{emptyText}</em>
  } else {
    return <span className={className}>{text}</span>
  }
}

UntitledIfEmpty.propTypes = {
  text: PropTypes.string,
  emptyText: PropTypes.string,
  className: PropTypes.string
}
