import * as api from '../api'

export const RECEIVE_RESPONDENTS = 'RECEIVE_RESPONDENTS'
export const FETCH_RESPONDENTS = 'FETCH_RESPONDENTS'
export const CREATE_RESPONDENT = 'CREATE_RESPONDENT'
export const UPDATE_RESPONDENT = 'UPDATE_RESPONDENT'
export const RECEIVE_RESPONDENTS_ERROR = 'RECEIVE_RESPONDENTS_ERROR'
export const RECEIVE_RESPONDENTS_STATS = 'RECEIVE_RESPONDENTS_STATS'
export const RECEIVE_RESPONDENTS_QUOTAS_STATS = 'RECEIVE_RESPONDENTS_QUOTAS_STATS'
export const SORT = 'RESPONDENTS_SORT'

export const fetchRespondents = (projectId, surveyId, limit, page = 1) => (dispatch, getState) => {
  const state = getState().respondents
  dispatch(startFetchingRespondents(surveyId, page))
  api.fetchRespondents(projectId, surveyId, limit, page, state.sortBy, state.sortAsc)
    .then(response => dispatch(receiveRespondents(surveyId, page, response.entities.respondents || {}, response.respondentsCount, response.result)))
}

export const fetchRespondentsStats = (projectId, surveyId) => dispatch => {
  api.fetchRespondentsStats(projectId, surveyId)
    .then(stats => dispatch(receiveRespondentsStats(stats)))
}

export const fetchRespondentsQuotasStats = (projectId, surveyId) => dispatch => {
  api.fetchRespondentsQuotasStats(projectId, surveyId)
    .then(stats => dispatch(receiveRespondentsQuotasStats(stats)))
}

export const receiveRespondentsStats = (response) => ({
  type: RECEIVE_RESPONDENTS_STATS,
  response
})

export const receiveRespondentsQuotasStats = (response) => ({
  type: RECEIVE_RESPONDENTS_QUOTAS_STATS,
  response
})

export const receiveRespondents = (surveyId, page, respondents, respondentsCount, order) => ({
  type: RECEIVE_RESPONDENTS,
  surveyId,
  page,
  respondents,
  respondentsCount,
  order
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

export const sortRespondentsBy = (projectId, surveyId, property) => (dispatch, getState) => {
  const state = getState().respondents
  const sortAsc = state.sortBy == property ? !state.sortAsc : true
  api.fetchRespondents(projectId, surveyId, state.page.size, 1, property, sortAsc)
    .then(response => dispatch(receiveRespondents(surveyId, 1, response.entities.respondents || {}, response.respondentsCount, response.result)))

  dispatch({
    type: SORT,
    property
  })
}
