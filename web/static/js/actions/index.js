export const RECEIVE_STUDIES = 'RECEIVE_STUDIES'
export const ADD_STUDY = 'ADD_STUDY'

export const receiveStudies = (response) => ({
  type: RECEIVE_STUDIES,
  response
})

export const addStudy = (response) => ({
  type: ADD_STUDY,
  response
})
