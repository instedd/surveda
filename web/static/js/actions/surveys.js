export const FETCH_SURVEYS_SUCCESS = 'FETCH_SURVEYS_SUCCESS'
export const CREATE_SURVEY = 'CREATE_SURVEY'
export const UPDATE_SURVEY = 'UPDATE_SURVEY'
export const FETCH_SURVEYS_ERROR = 'FETCH_SURVEYS_ERROR'

export const fetchSurveysSuccess = (response) => ({
  type: FETCH_SURVEYS_SUCCESS,
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

export const fetchSurveysError = (error) => ({
  type: FETCH_SURVEYS_ERROR,
  error
})
