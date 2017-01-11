// @flow
import * as api from '../api'

export const RECEIVE = 'PROJECTS_RECEIVE'
export const RECEIVE_ERROR = 'PROJECTS_RECEIVE_ERROR'
export const FETCH = 'PROJECTS_FETCH'
export const NEXT_PAGE = 'PROJECTS_NEXT_PAGE'
export const PREVIOUS_PAGE = 'PROJECTS_PREVIOUS_PAGE'
export const SORT = 'PROJECTS_SORT'

export const fetchProjects = () => (dispatch: Function, getState: () => Store) => {
  const state = getState()

  // Don't fetch projects if they are already being fetched
  if (state.projects.fetching) {
    return
  }

  dispatch(startFetchingProjects())
  return api.fetchProjects()
    .then(response => dispatch(receiveProjects(response.entities.projects || {})))
}

export const startFetchingProjects = () => ({
  type: FETCH
})

export const receiveProjects = (projects: IndexedList<Project>) => ({
  type: RECEIVE,
  projects
})

export const nextProjectsPage = () => ({
  type: NEXT_PAGE
})

export const previousProjectsPage = () => ({
  type: PREVIOUS_PAGE
})

export const sortProjectsBy = (property: string) => ({
  type: SORT,
  property
})
