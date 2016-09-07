import React from 'react'
import { Link, withRouter } from 'react-router'

export const TabLink = withRouter(props => {
  const {children, to, router, params, location, routes, ...attrs} = props;

  attrs.className = ""
  if (router.isActive(to)) {
    attrs.className = "active"
  }
  attrs.className += " tab col"

  return (
    <li {...attrs}>
      <Link to={to}>{children}</Link>
    </li>
  )
})
