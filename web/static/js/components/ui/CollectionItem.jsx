import React, { PropTypes } from 'react'
import { animatedScrollTo } from '../ui'

export const CollectionItem = ({ path, icon, text, completed, className }) => {
  return (
    <li className={`collection-item ${completed ? 'completed' : ''} ${className || ''}`}>
      <a href={path} onClick={(e) => animatedScrollTo(e, path)}>
        <i className='material-icons'>{completed ? 'check_circle' : icon}</i>
        <span>{text}</span>
        <span className='arrowright'>
          <i className='material-icons'>keyboard_arrow_right</i>
        </span>
      </a>
    </li>
  )
}

CollectionItem.propTypes = {
  path: PropTypes.string.isRequired,
  icon: PropTypes.string.isRequired,
  text: PropTypes.string.isRequired,
  completed: PropTypes.bool.isRequired,
  className: PropTypes.string
}
