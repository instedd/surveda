import React from 'react'
import { Link, withRouter } from 'react-router'

export default withRouter(props => {
  const { children, className, survey } = props

  let to = `/projects/${survey.projectId}/surveys/${survey.id}`

  console.log(survey)

  if (survey.state == 'pending') {
    to = to + '/edit'
  }

  return (
    <Link className={className} to={to}>{children}</Link>
  )
})
