import React, { PropTypes } from 'react'
import merge from 'lodash/merge'
import QuestionnaireSteps from './QuestionnaireSteps'
import * as editorActions from '../actions/questionnaireEditor'

const QuestionnaireForm = ({ onSubmit, questionnaireEditor, dispatch }) => {
  let nameInput
  let modesInput

  if (!questionnaireEditor.questionnaire) {
    return <div>Loading...</div>
  }

  const questionnaire = questionnaireEditor.questionnaire

  return (
    <div className='row'>
      <div className='row'>
        <div className='col s12 m4'>
          <div className='row'>
            <div className='input-field col s12'>
              <input type='text' id='questionnaire_name' placeholder='Questionnaire name' defaultValue={questionnaire.name} ref={node => { nameInput = node }} />
              <label className='active' htmlFor='questionnaire_name'>Questionnaire Name</label>
            </div>
          </div>
          <div className='row'>
            <div className='input-field col s12'>
              <select defaultValue={'SMS'} ref={node => { modesInput = node; $(node).material_select() }}>
                <option value='SMS'>SMS</option>
                <option value='IVR'>IVR</option>
                <option value='SMS,IVR'>SMS and IVR</option>
              </select>
              <label>Mode</label>
            </div>
          </div>
        </div>
        <div className='col s12 m8'>
          <div className='row'>
            <div className='col s12'>
              <QuestionnaireSteps
                questionnaireEditor={questionnaireEditor}
                />
            </div>
          </div>
        </div>
      </div>
      <div className='row'>
        <div className='col s12'>
          <button type='button' className='btn waves-effect waves-light' onClick={() => {
            let newQuestionnaire = merge({}, questionnaire, {name: nameInput.value})
            newQuestionnaire.modes = modesInput.value.split(',')
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
  questionnaireEditor: PropTypes.object.isRequired
}

export default QuestionnaireForm
