import * as api from '../api'

export const RECEIVE_SURVEYS = 'RECEIVE_SURVEYS'
export const CREATE_SURVEY = 'CREATE_SURVEY'
export const UPDATE_SURVEY = 'UPDATE_SURVEY'
export const RECEIVE_SURVEYS_ERROR = 'RECEIVE_SURVEYS_ERROR'

export const fetchSurveys = (projectId) => dispatch => {
  api.fetchSurveys(projectId)
    .then(surveys => dispatch(receiveSurveys(surveys)))
}

export const fetchSurvey = (projectId, surveyId) => dispatch => {
  api.fetchSurvey(projectId, surveyId)
    .then(survey => dispatch(receiveSurveys(survey)))
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
