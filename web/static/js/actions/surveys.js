import * as api from '../api'

export const RECEIVE_SURVEYS = 'RECEIVE_SURVEYS'
export const CREATE_SURVEY = 'CREATE_SURVEY'
export const UPDATE_SURVEY = 'UPDATE_SURVEY'
export const RECEIVE_SURVEYS_ERROR = 'RECEIVE_SURVEYS_ERROR'

export const fetchSurveys = (projectId) => (dispatch, getState) => {
  return api
    .fetchSurveys(projectId)
    .then(surveys => dispatch(receiveSurveys(surveys)))
    .then(() => getState().surveys)
}

export const fetchSurvey = (projectId, surveyId) => (dispatch, getState) => {
  return api.fetchSurvey(projectId, surveyId)
    .then(survey => dispatch(receiveSurveys(survey)))
    .then(() => getState().surveys[surveyId])
}

export const fetchSurveyIfNeeded = (projectId, surveyId) => {
  return (dispatch, getState) => {
    if (shouldFetchSurvey(getState(), projectId, surveyId)) {
      return dispatch(fetchSurvey(projectId, surveyId))
    }
  }
}

const shouldFetchSurvey = (state, projectId, surveyId) => {
  return state.surveys
}

export const receiveSurveys = (response) => ({
  type: RECEIVE_SURVEYS,
  response
})

export const createSurvey = (response) => ({
  type: CREATE_SURVEY,
  id: response.result,
  survey: response.entities.surveys[response.result]
})

export const updateSurvey = (response) => ({
  type: UPDATE_SURVEY,
  id: response.result,
  survey: response.entities.surveys[response.result]
})

export const receiveSurveysError = (error) => ({
  type: RECEIVE_SURVEYS_ERROR,
  error
})