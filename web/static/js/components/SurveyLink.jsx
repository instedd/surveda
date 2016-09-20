import React from 'react'
import { Link, withRouter } from 'react-router'

export default withRouter(props => {
  const { children, className, survey } = props

  let to = `/projects/${survey.projectId}/surveys/${survey.id}`

  if (survey.state == 'not_ready' || survey.state == 'ready') {
    to = to + '/edit'
  }

  return (
    <Link className={className} to={to}>{children}</Link>
  )
})
