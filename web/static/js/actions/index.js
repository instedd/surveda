export const FETCH_STUDIES_SUCCESS = 'FETCH_STUDIES_SUCCESS'
export const ADD_STUDY = 'ADD_STUDY'
export const FETCH_STUDIES_ERROR = 'FETCH_STUDIES_ERROR'

export const fetchStudiesSuccess = (response) => ({
  type: FETCH_STUDIES_SUCCESS,
  response
})

export const addStudy = (response) => ({
  type: ADD_STUDY,
  response
})

export const fetchStudiesError = (error) => ({
  type: FETCH_STUDIES_ERROR,
  error
})
