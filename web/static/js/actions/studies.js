export const FETCH_STUDIES_SUCCESS = 'FETCH_STUDIES_SUCCESS'
export const CREATE_STUDY = 'CREATE_STUDY'
export const UPDATE_STUDY = 'UPDATE_STUDY'
export const FETCH_STUDIES_ERROR = 'FETCH_STUDIES_ERROR'

export const fetchStudiesSuccess = (response) => ({
  type: FETCH_STUDIES_SUCCESS,
  response
})

export const createStudy = (response) => ({
  type: CREATE_STUDY,
  id: response.result,
  study: response.entities.studies[response.result]
})

export const updateStudy = (response) => ({
  type: UPDATE_STUDY,
  id: response.result,
  study: response.entities.studies[response.result]
})

export const fetchStudiesError = (error) => ({
  type: FETCH_STUDIES_ERROR,
  error
})
