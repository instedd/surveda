import * as api from "../api"

export const RECEIVE_PROJECT = "RECEIVE_PROJECT"
export const FETCH_PROJECT = "FETCH_PROJECT"
export const CREATE_PROJECT = "CREATE_PROJECT"
export const UPDATE_PROJECT = "UPDATE_PROJECT"
export const CLEAR_PROJECT = "CLEAR_PROJECT"

export const fetchProject = (projectId) => (dispatch, getState) => {
  const state = getState()

  // Don't fetch same project twice
  if (state.project.fetching && state.project.projectId == projectId) {
    return
  }

  // Start fetching the project
  dispatch(startFetchingProject(projectId))

  // Check if the project is loaded in the projects state,
  // but only if there isn't a project loaded
  // (this can happen when a user enters a project)
  if (!state.project.projectId && state.projects.items) {
    const project = state.projects.items[projectId]
    if (project) {
      dispatch(receiveProject(project))
      return
    }
  }

  api
    .fetchProject(projectId)
    .then((response) => dispatch(receiveProject(response.entities.projects[response.result])))
}

export const startFetchingProject = (projectId) => ({
  type: FETCH_PROJECT,
  projectId,
})

export const receiveProject = (project) => ({
  type: RECEIVE_PROJECT,
  project,
})

export const createProject = (project) => ({
  type: CREATE_PROJECT,
  project,
})

export const updateProject = (project) => ({
  type: UPDATE_PROJECT,
  project,
})

export const clearProject = () => ({
  type: CLEAR_PROJECT,
})
