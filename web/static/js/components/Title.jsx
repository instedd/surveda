import React, { PropTypes } from 'react'
import { Link } from 'react-router'

const Title = ({ params, project, survey, questionnaire, routes }) => {
  let name

  // Find deepest entity available
  if (questionnaire) {
    name = questionnaire.name
  } else if (survey) {
    name = survey.name
  } else if (project) {
    name = project.name
  } else {
    // Find last route component that has a name
    for(var i = routes.length - 1; i >= 0; i--) {
      if (routes[i].name) {
        name = routes[i].name
        break
      }
    }
  }

	return (
		<nav id="Breadcrumb">
      <div className="nav-wrapper">
        <div className="row">
          <div className="breadcrumbs">
            <div className="logo"><img src="/images/logo.png" width="28px" /></div>
            <a className="breadcrumb">{name}</a>
          </div>
        </div>
      </div>
    </nav>
	)
}

export default Title