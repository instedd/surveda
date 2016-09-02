import React from 'react'
import { Link, withRouter } from 'react-router'

export const TabLink = withRouter(props => {
  const {children, to, router, params, location, routes, ...attrs} = props;

  if (router.isActive(to)) {
    attrs.className = "active"
  }

  return (
    <li {...attrs}>
      <Link to={to}>{children}</Link>
    </li>
  )
})
