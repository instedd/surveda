import * as api from '../api'

export const RECEIVE_QUESTIONNAIRES = 'RECEIVE_QUESTIONNAIRES'
export const CREATE_QUESTIONNAIRE = 'CREATE_QUESTIONNAIRE'
export const UPDATE_QUESTIONNAIRE = 'UPDATE_QUESTIONNAIRE'
export const RECEIVE_QUESTIONNAIRES_ERROR = 'RECEIVE_QUESTIONNAIRES_ERROR'

export const fetchQuestionnaires = (projectId) => dispatch => {
  api.fetchQuestionnaires(projectId)
    .then(questionnaires => dispatch(receiveQuestionnaires(questionnaires)))
}

export const fetchQuestionnaire = (projectId, questionnaireId) => dispatch => {
  api.fetchQuestionnaire(projectId, questionnaireId)
    .then(questionnaire => dispatch(receiveQuestionnaires(questionnaire)))
}

export const receiveQuestionnaires = (response) => ({
  type: RECEIVE_QUESTIONNAIRES,
  response
})

export const createQuestionnaire = (response) => ({
  type: CREATE_QUESTIONNAIRE,
  id: response.result,
  questionnaire: response.entities.questionnaires[response.result]
})

export const updateQuestionnaire = (response) => ({
  type: UPDATE_QUESTIONNAIRE,
  id: response.result,
  questionnaire: response.entities.questionnaires[response.result]
})

export const receiveQuestionnairesError = (error) => ({
  type: RECEIVE_QUESTIONNAIRES_ERROR,
  error
})
