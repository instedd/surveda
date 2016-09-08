import React, { PropTypes } from 'react'
import merge from 'lodash/merge'
import { Link } from 'react-router'

const SurveyForm = ({ onSubmit, survey, children, project }) => {
  return (
    <div>
      <div className="row">
        <div className="col s12" />
      </div>
      <div className="row">
        <div className="col s4" style={{border: `1px solid black`, height: `400px`}}>
          <label>Progress bar</label>
          <div>
            Select a questionnaire
          </div>
          <div>
            Upload your respondents list
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
        <div className="col s8">
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
