import * as api from '../api'

export const RECEIVE_SURVEYS = 'RECEIVE_SURVEYS'
export const SET_SURVEY = 'SET_SURVEY'
export const RECEIVE_SURVEYS_ERROR = 'RECEIVE_SURVEYS_ERROR'

export const fetchSurveys = (projectId) => (dispatch, getState) => {
  return api
    .fetchSurveys(projectId)
    .then(surveys => dispatch(receiveSurveys(surveys)))
    .then(() => getState().surveys)
}

export const fetchSurvey = (projectId, surveyId) => (dispatch, getState) => {
  return api.fetchSurvey(projectId, surveyId)
    .then(survey => dispatch(setSurvey(survey)))
    .then(() => getState().surveys[surveyId])
}

export const fetchSurveyIfNeeded = (projectId, surveyId) => {
  return (dispatch, getState) => {
    if (shouldFetchSurvey(getState())) {
      return dispatch(fetchSurvey(projectId, surveyId))
    }
  }
}

const shouldFetchSurvey = (state) => {
  return state.surveys === {}
}

export const receiveSurveys = (response) => ({
  type: RECEIVE_SURVEYS,
  response
})

export const setSurvey = (response) => ({
  type: SET_SURVEY,
  id: response.result,
  survey: response.entities.surveys[response.result]
})

export const receiveSurveysError = (error) => ({
  type: RECEIVE_SURVEYS_ERROR,
  error
})
