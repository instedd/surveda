import React, { PropTypes } from 'react'
import merge from 'lodash/merge'
import { Link } from 'react-router'

const SurveyForm = ({ onSubmit, survey }) => {
  let input
  return (
    <div>
      <div>
        <label>Survey Name</label>
        <div>
          <input type="text" placeholder="Survey name" defaultValue={survey.name} ref={ node => { input = node }
          }/>
        </div>
      </div>
      <br/>
      <div>
        <button type="button" onClick={() =>
          onSubmit(merge({}, survey, {name: input.value}))
        }>
          Submit
        </button>
        <Link to={`/projects/${survey.projectId}/surveys`}> Back</Link>
      </div>
    </div>
  )
}

SurveyForm.propTypes = {
  onSubmit: PropTypes.func.isRequired,
  survey: PropTypes.object.isRequired
}

export default SurveyForm
