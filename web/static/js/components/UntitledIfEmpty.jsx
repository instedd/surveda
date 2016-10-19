import React from 'react'

export default ({ text }) => {
  if (!text || text.trim() === '') {
    return <i>Untitled</i>
  } else {
    return <span>{text}</span>
  }
}
