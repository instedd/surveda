import React from 'react'
// import { Link } from 'react-router'
import { EditableTitleLabel } from './EditableTitleLabel'
import merge from 'lodash/merge'
import { updateSurvey, updateProject, updateQuestionnaire } from '../api'
import * as projectsActions from '../actions/projects'
import * as surveysActions from '../actions/surveys'
import * as questionnairesActions from '../actions/questionnaires'
import * as questionnaireEditorActions from '../actions/questionnaireEditor'

const Title = ({ params, project, survey, questionnaire, routes, dispatch }) => {
  let name
  let entity = null
  let titleOwner

  // Find deepest entity available
  if (questionnaire) {
    name = questionnaire.name
    entity = 'questionnaire'
    titleOwner = questionnaire
  } else if (survey) {
    name = survey.name
    entity = 'survey'
    titleOwner = survey
  } else if (project) {
    name = project.name
    entity = 'project'
    titleOwner = project
  } else {
    // Find last route component that has a name
    for (var i = routes.length - 1; i >= 0; i--) {
      if (routes[i].name) {
        name = routes[i].name
        break
      }
    }
  }

  return (
    <nav id='MainNav'>
      <div className='nav-wrapper'>
        <div className='row'>
          <div className='col s12'>
            <div className='logo'><img src='/images/logo.png' width='28px' /></div>
            {entity
            ? <EditableTitleLabel title={name} onSubmit={(value) => { handleSubmit(titleOwner, entity, value, dispatch) }} />
            : <a className='breadcrumb'>{name}</a>
            }
          </div>
        </div>
      </div>
    </nav>
  )
}

var handleSubmit = (oldObject, entity, inputValue, dispatch) => {
  const newValue = {
    name: inputValue
  }

  const newObject = merge({}, oldObject, newValue)

  console.log('estamos submitteando: ', oldObject, entity, inputValue, newObject)

  switch (entity) {
    case 'questionnaire':
      updateQuestionnaire(newObject.projectId, newObject)
          .then(updatedQuestionnaire => dispatch(questionnairesActions.receiveQuestionnaires(updatedQuestionnaire)))
          .then(() => dispatch(questionnaireEditorActions.changeQuestionnaireName(inputValue)))
          .catch((e) => dispatch(questionnairesActions.receiveQuestionnairesError(e)))
      break
    case 'survey':
      updateSurvey(newObject.projectId, newObject)
          .then(updatedSurvey => dispatch(surveysActions.setSurvey(updatedSurvey)))
          .catch((e) => dispatch(surveysActions.receiveSurveysError(e)))
      break
    case 'project':
      updateProject(newObject)
          .then(project => dispatch(projectsActions.updateProject(project)))
          .catch((e) => dispatch(projectsActions.receiveProjectsError(e)))
      break
    default:
      console.log('This should be never reached')
  }
}

export default Title
