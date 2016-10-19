import React from 'react'

export default ({ text, emptyText = 'Untitled' }) => {
  if (!text || text.trim() === '') {
    return <em>{emptyText}</em>
  } else {
    return <span>{text}</span>
  }
}
