import React, { PropTypes } from 'react'
import merge from 'lodash/merge'
import { Link } from 'react-router'

const QuestionnaireForm = ({ onSubmit, project, questionnaire }) => {
  let nameInput
  let modesInput
  if (!project || !questionnaire) {
    return <div>Loading...</div>
  }

  let defaultMode = (questionnaire.modes || ["SMS"]).join(",")

  return (
    <div>
      <div>
        <label>Questionnaire Name</label>
        <div>
          <input type="text" placeholder="Questionnaire name" defaultValue={questionnaire.name} ref={ node => { nameInput = node }
          }/>
        </div>
      </div>
      <div>
        <label>Mode</label>
        <div>
          <select defaultValue={defaultMode} ref={ node => { modesInput = node }}>
            <option value="SMS">SMS</option>
            <option value="IVR">IVR</option>
            <option value="SMS,IVR">SMS and IVR</option>
          </select>
        </div>
      </div>
      <br/>
      <div>
        <button type="button" onClick={() => {
          let newQuestionnaire = merge({}, questionnaire, {name: nameInput.value})
          newQuestionnaire.modes = modesInput.value.split(",")
          return onSubmit(newQuestionnaire)
        }}>
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
}

export default QuestionnaireForm
