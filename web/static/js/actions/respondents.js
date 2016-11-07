import * as api from '../api'

export const RECEIVE_RESPONDENTS = 'RECEIVE_RESPONDENTS'
export const FETCH_RESPONDENTS = 'FETCH_RESPONDENTS'
export const CREATE_RESPONDENT = 'CREATE_RESPONDENT'
export const UPDATE_RESPONDENT = 'UPDATE_RESPONDENT'
export const REMOVE_RESPONDENTS = 'REMOVE_RESPONDENTS'
export const RECEIVE_RESPONDENTS_ERROR = 'RECEIVE_RESPONDENTS_ERROR'
export const RECEIVE_RESPONDENTS_STATS = 'RECEIVE_RESPONDENTS_STATS'
export const INVALID_RESPONDENTS = 'INVALID_RESPONDENTS'
export const CLEAR_INVALIDS = 'CLEAR_INVALIDS'

export const fetchRespondents = (projectId, surveyId, limit, page = 1) => dispatch => {
  dispatch(startFetchingRespondents(surveyId, page))
  api.fetchRespondents(projectId, surveyId, limit, page)
    .then(response => dispatch(receiveRespondents(surveyId, page, response.entities.respondents || {}, response.respondentsCount)))
}

export const fetchRespondentsStats = (projectId, surveyId) => dispatch => {
  api.fetchRespondentsStats(projectId, surveyId)
    .then(stats => dispatch(receiveRespondentsStats(stats)))
}

export const receiveRespondentsStats = (response) => ({
  type: RECEIVE_RESPONDENTS_STATS,
  response
})

export const receiveRespondents = (surveyId, page, respondents, respondentsCount) => ({
  type: RECEIVE_RESPONDENTS,
  surveyId,
  page,
  respondents,
  respondentsCount
})

export const removeRespondents = (response) => ({
  type: REMOVE_RESPONDENTS,
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

export const startFetchingRespondents = (surveyId, page) => ({
  type: FETCH_RESPONDENTS,
  surveyId,
  page
})

export const receiveInvalids = (invalidRespondents) => ({
  type: INVALID_RESPONDENTS,
  invalidRespondents: invalidRespondents
})

export const clearInvalids = () => ({
  type: CLEAR_INVALIDS
})
