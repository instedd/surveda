import React from 'react'
import { Link, withRouter } from 'react-router'

export const CollectionItem = withRouter(props => {
  const { path, icon, text, completed, router, className } = props
  const active = router.isActive(path) ? "active" : ""

  return(
    <li className={`collection-item ${completed ? "completed" : ""} ${active} ${className}`}>
      <Link to={path}>
        <i className="material-icons">{completed ? "check_circle" : icon}</i>
        <span>{text}</span>
        <span className="arrowright">
          <i className="material-icons">keyboard_arrow_right</i>
        </span>
      </Link>
    </li>
  )
})
