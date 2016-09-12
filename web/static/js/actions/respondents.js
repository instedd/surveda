import * as api from '../api'

export const RECEIVE_RESPONDENTS = 'RECEIVE_RESPONDENTS'
export const CREATE_RESPONDENT = 'CREATE_RESPONDENT'
export const UPDATE_RESPONDENT = 'UPDATE_RESPONDENT'
export const RECEIVE_RESPONDENTS_ERROR = 'RECEIVE_RESPONDENTS_ERROR'

export const fetchRespondents = (projectId, surveyId) => dispatch => {
  api.fetchRespondents(projectId, surveyId)
    .then(respondents => dispatch(receiveRespondents(respondents)))
}

export const fetchRespondent = (projectId, respondentId) => dispatch => {
  api.fetchRespondent(projectId, respondentId)
    .then(respondent => dispatch(receiveRespondents(respondent)))
}

export const receiveRespondents = (response) => ({
  type: RECEIVE_RESPONDENTS,
  response
})

export const createRespondent = (response) => ({
  type: CREATE_RESPONDENT,
  id: response.result,
  respondent: response.entities.respondents[response.result]
})

export const updateRespondent = (response) => ({
  type: UPDATE_RESPONDENT,
  id: response.result,
  respondent: response.entities.respondents[response.result]
})

export const receiveRespondentsError = (error) => ({
  type: RECEIVE_RESPONDENTS_ERROR,
  error
})
