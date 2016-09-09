import React, { PropTypes } from 'react'
import merge from 'lodash/merge'
import { Link } from 'react-router'

const SurveyForm = ({ onSubmit, survey, children, project }) => {
  let linkPath = `/projects/${project.id}/surveys/${survey.id}/edit/`
  return (
    <div>
      <div className="row">
        <div className="col s12" />
      </div>
      <div className="row">
        <div className="col s4" style={{border: `1px solid black`, height: `400px`}}>
          <label>Progress bar</label>
          <div>
            <Link to={`${linkPath}questionnaire`}>Select a questionnaire</Link>
          </div>
          <div>
            <Link to={`${linkPath}respondents`}>Upload your respondents list</Link>
          </div>
          <div>
            Select mode and channels
          </div>
          <div>
            Setup cutoff rules
          </div>
          <div>
            Setup a schedule
          </div>
        </div>
        <div className="col s1"/>
        <div className="col s7">
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
