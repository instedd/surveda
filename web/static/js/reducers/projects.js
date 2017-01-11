// @flow
import * as actions from '../actions/projects'
import { itemsOrder, sortItems, nextPage, previousPage } from '../dataTable'

const initialState = {
  fetching: false,
  items: null,
  filter: null,
  order: null,
  sortBy: 'updatedAt',
  sortAsc: false,
  page: {
    index: 0,
    size: 5
  }
}
export default (state: ListStore<Project> = initialState, action: any): ListStore<Project> => {
  switch (action.type) {
    case actions.FETCH: return fetchProjects(state, action)
    case actions.RECEIVE: return receiveProjects(state, action)
    case actions.NEXT_PAGE: return nextPage(state)
    case actions.PREVIOUS_PAGE: return previousPage(state)
    case actions.SORT: return sortItems(state, action)
    default: return state
  }
}

const fetchProjects = (state, action) => ({
  ...state,
  fetching: true,
  page: {
    index: 0,
    size: 5
  }
})

const receiveProjects = (state, action) => {
  const projects = action.projects
  let order = itemsOrder(projects, state.sortBy, state.sortAsc)
  return {
    ...state,
    fetching: false,
    items: projects,
    order
  }
}
