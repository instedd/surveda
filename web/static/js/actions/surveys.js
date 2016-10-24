import * as api from '../api'

export const RECEIVE_SURVEYS = 'RECEIVE_SURVEYS'
export const FETCH_SURVEYS = 'FETCH_SURVEYS'
export const SET_SURVEY = 'SET_SURVEY'
export const RECEIVE_SURVEYS_ERROR = 'RECEIVE_SURVEYS_ERROR'
export const NEXT_SURVEYS_PAGE = 'NEXT_SURVEYS_PAGE'
export const PREVIOUS_SURVEYS_PAGE = 'PREVIOUS_SURVEYS_PAGE'
export const SORT_SURVEYS = 'SORT_SURVEYS'

export const fetchSurveys = (projectId) => (dispatch, getState) => {
  const state = getState()

  // Don't fetch surveys if they are already being fetched
  // for that same project
  if (state.surveys.fetching && state.surveys.projectId === projectId) {
    return
  }

  dispatch(startFetchingSurveys(projectId))

  return api
    .fetchSurveys(projectId)
    .then(response => dispatch(receiveSurveys(projectId, response.entities.surveys || [])))
    .then(() => getState().surveys.items)
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

export const startFetchingSurveys = (projectId) => ({
  type: FETCH_SURVEYS,
  projectId
})

export const receiveSurveys = (projectId, surveys) => ({
  type: RECEIVE_SURVEYS,
  projectId,
  surveys
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

export const nextSurveysPage = () => ({
  type: NEXT_SURVEYS_PAGE
})

export const previousSurveysPage = () => ({
  type: PREVIOUS_SURVEYS_PAGE
})

export const sortSurveysBy = (property) => ({
  type: SORT_SURVEYS,
  property
})
