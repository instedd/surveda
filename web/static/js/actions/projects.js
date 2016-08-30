export const FETCH_PROJECTS_SUCCESS = 'FETCH_PROJECTS_SUCCESS'
export const CREATE_PROJECT = 'CREATE_PROJECT'
export const UPDATE_PROJECT = 'UPDATE_PROJECT'
export const FETCH_PROJECTS_ERROR = 'FETCH_PROJECTS_ERROR'

export const fetchProjectsSuccess = (response) => ({
  type: FETCH_PROJECTS_SUCCESS,
  response
})

export const createProject = (response) => ({
  type: CREATE_PROJECT,
  id: response.result,
  project: response.entities.projects[response.result]
})

export const updateProject = (response) => ({
  type: UPDATE_PROJECT,
  id: response.result,
  project: response.entities.projects[response.result]
})

export const fetchProjectsError = (error) => ({
  type: FETCH_PROJECTS_ERROR,
  error
})
