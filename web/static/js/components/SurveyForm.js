import React, { PropTypes } from 'react'
import merge from 'lodash/merge'
import { Link } from 'react-router'

const SurveyForm = ({ onSubmit, survey, children, project }) => {
  let input
  return (
    <div>
      <div>
        <div className="col-md-1" />
        <div className="col-md-1">
          <img src={`/images/header_icon.png`}/>
        </div>
        <div className="col-md-8" >
          <h4>
            My Projects > {project.name} > {survey.name}
          </h4>
        </div>
      </div>
      <div className="col-md-12" />
      <div>
        <div className="col-md-4" style={{border: `1px solid black`, height: `400px`}}>
          <label>Progress bar</label>
          <div>
            Select a questionnaire
          </div>
          <div>
            Item 2
          </div>
          <div>
            Item 3
          </div>
          <div>
            Item 4
          </div>
          <div>
            Item 5
          </div>
        </div>
        <div className="col-md-8">
          {children}
        </div>
      </div>
    </div>
  )
}

SurveyForm.propTypes = {
  project: PropTypes.object.isRequired,
  survey: PropTypes.object.isRequired
}

export default SurveyForm
