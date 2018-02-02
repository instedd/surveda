// @flow
import * as api from '../api'
import merge from 'lodash/merge'

export const RECEIVE = 'PROJECTS_RECEIVE'
export const RECEIVE_ERROR = 'PROJECTS_RECEIVE_ERROR'
export const FETCH = 'PROJECTS_FETCH'
export const NEXT_PAGE = 'PROJECTS_NEXT_PAGE'
export const PREVIOUS_PAGE = 'PROJECTS_PREVIOUS_PAGE'
export const SORT = 'PROJECTS_SORT'
export const REMOVE = 'PROJECTS_REMOVE'

export const fetchProjects = (options: Object) => (dispatch: Function, getState: () => Store) => {
  const state = getState()

  // Don't fetch projects if they are already being fetched
  if (state.projects.fetching) {
    return
  }

  dispatch(startFetchingProjects(options['archived']))
  return api.fetchProjects(options)
    .then(response => dispatch(receiveProjects(response.entities.projects || {}, options['archived'])))
}

export const startFetchingProjects = (archived: boolean): FilteredAction => ({
  type: FETCH,
  archived
})

export const receiveProjects = (items: IndexedList<Project>, archived: boolean): ReceiveFilteredItemsAction => ({
  type: RECEIVE,
  archived,
  items
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

export const archive_or_unarchive = (project: Project, action: string) => (dispatch: Function, getState: () => Store) => {
  const new_status = (action == 'archive') ? true : false
  project = merge({}, project, {archived: new_status})
  api.updateProject(project).then(response => {
    dispatch(remove(response.entities.projects[response.result]))
  })
}

export const remove = (project: Project) => ({
  type: REMOVE,
  id: project.id
})

