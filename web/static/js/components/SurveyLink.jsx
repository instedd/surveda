import React from 'react'
import { Link, withRouter } from 'react-router'
import surveyRoute from './SurveyRoute'
export default withRouter(({ children, className, survey }) => {
  const to = surveyRoute(survey)

  return (
    <Link className={className} to={to}>{children}</Link>
  )
})
