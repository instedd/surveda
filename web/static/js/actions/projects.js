import * as api from '../api'

export const RECEIVE_PROJECTS = 'RECEIVE_PROJECTS'
export const CREATE_PROJECT = 'CREATE_PROJECT'
export const UPDATE_PROJECT = 'UPDATE_PROJECT'
export const RECEIVE_PROJECTS_ERROR = 'RECEIVE_PROJECTS_ERROR'

export const fetchProjects = () => dispatch => {
  api.fetchProjects()
    .then(projects => dispatch(receiveProjects(projects)))
}

export const fetchProject = (projectId) => dispatch => {
  api.fetchProject(projectId)
    .then(project => dispatch(receiveProjects(project)))
}

export const fetchProjectIfNeeded = (projectId) => {
  return (dispatch, getState) => {
    if (shouldFetchProject(getState(), projectId)) {
      return dispatch(fetchProject(projectId))
    }
  }
}

const shouldFetchProject = (state, projectId) => {
  return state.projects
}

export const receiveProjects = (response) => ({
  type: RECEIVE_PROJECTS,
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

export const receiveProjectsError = (error) => ({
  type: RECEIVE_PROJECTS_ERROR,
  error
})