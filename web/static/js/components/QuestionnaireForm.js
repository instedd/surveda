import React, { PropTypes } from 'react'
import merge from 'lodash/merge'
import { Link } from 'react-router'

const QuestionnaireForm = ({ onSubmit, project, questionnaire }) => {
  let input
  if (!project || !questionnaire) {
    return <div>Loading...</div>
  }

  return (
    <div>
      <div>
        <label>Questionnaire Name</label>
        <div>
          <input type="text" placeholder="Questionnaire name" defaultValue={questionnaire.name} ref={ node => { input = node }
          }/>
        </div>
      </div>
      <br/>
      <div>
        <button type="button" onClick={() =>
          onSubmit(merge({}, questionnaire, {name: input.value}))
        }>
          Submit
        </button>
        <Link to={`/projects/${project.id}/questionnaires`}> Back</Link>
      </div>
    </div>
  )
}

QuestionnaireForm.propTypes = {
  onSubmit: PropTypes.func.isRequired,
  project: PropTypes.object.isRequired,
  questionnaire: PropTypes.object.isRequired
}

export default QuestionnaireForm
