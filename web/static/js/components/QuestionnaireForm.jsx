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
    <div className="row">
      <div className="col s12 m8">
        <div className="row">
          <div className="input-field col s12">
            <input type="text" id="questionnaire_name" placeholder="Questionnaire name" defaultValue={questionnaire.name} ref={ node => { nameInput = node }}/>
            <label className="active" htmlFor="questionnaire_name">Questionnaire Name</label>
          </div>
        </div>
      </div>
      <div className="col s12 m3 offset-m1">
        <div className="row">
          <div className="input-field col s12">
            <select defaultValue={defaultMode} ref={ node => { modesInput = node; $(node).material_select() }}>
              <option value="SMS">SMS</option>
              <option value="IVR">IVR</option>
              <option value="SMS,IVR">SMS and IVR</option>
            </select>
            <label>Mode</label>
          </div>
        </div>
      </div>
      <div className="row">
        <div className="col s12">
          <button type="button" className="btn waves-effect waves-light" onClick={() => {
            let newQuestionnaire = merge({}, questionnaire, {name: nameInput.value})
            newQuestionnaire.modes = modesInput.value.split(",")
            return onSubmit(newQuestionnaire)
          }}>
            Submit
          </button>
        </div>
      </div>
    </div>
  )
}

QuestionnaireForm.propTypes = {
  onSubmit: PropTypes.func.isRequired,
  project: PropTypes.object.isRequired,
}

export default QuestionnaireForm
