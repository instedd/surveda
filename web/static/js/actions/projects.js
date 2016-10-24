import * as api from '../api'

export const RECEIVE_PROJECTS = 'RECEIVE_PROJECTS'
export const RECEIVE_PROJECTS_ERROR = 'RECEIVE_PROJECTS_ERROR'
export const FETCH_PROJECTS = 'FETCH_PROJECTS'
export const NEXT_PROJECTS_PAGE = 'NEXT_PROJECTS_PAGE'
export const PREVIOUS_PROJECTS_PAGE = 'PREVIOUS_PROJECTS_PAGE'
export const SORT_PROJECTS = 'SORT_PROJECTS'

export const fetchProjects = () => (dispatch, getState) => {
  const state = getState()

  // Don't fetch projects if they are already being fetched
  if (state.projects.fetching) {
    return
  }

  dispatch(startFetchingProjects())
  return api.fetchProjects()
    .then(response => dispatch(receiveProjects(response.entities.projects || [])))
}

export const startFetchingProjects = () => ({
  type: FETCH_PROJECTS
})

export const receiveProjects = (projects) => ({
  type: RECEIVE_PROJECTS,
  projects
})

export const receiveProjectsError = (error) => ({
  type: RECEIVE_PROJECTS_ERROR,
  error
})

export const nextProjectsPage = () => ({
  type: NEXT_PROJECTS_PAGE
})

export const previousProjectsPage = () => ({
  type: PREVIOUS_PROJECTS_PAGE
})

export const sortProjectsBy = (property) => ({
  type: SORT_PROJECTS,
  property
})
