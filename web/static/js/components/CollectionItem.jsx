import React from 'react'

export const CollectionItem = (props) => {
  const { path, icon, text, completed, className } = props

  return (
    <li className={`collection-item ${completed ? 'completed' : ''} ${className || ''}`}>
      <a href={path}>
        <i className='material-icons'>{completed ? 'check_circle' : icon}</i>
        <span>{text}</span>
        <span className='arrowright'>
          <i className='material-icons'>keyboard_arrow_right</i>
        </span>
      </a>
    </li>
  )
}
