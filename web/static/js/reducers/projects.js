import * as actions from '../actions/projects'
import { itemsOrder, sortItems, nextPage, previousPage } from '../dataTable'

const initialState = {
  fetching: false,
  items: null,
  order: null,
  sortBy: null,
  sortAsc: true,
  page: {
    index: 0,
    size: 5
  }
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.FETCH_PROJECTS:
      return {
        ...state,
        fetching: true,
        page: {
          index: 0,
          size: 5
        }
      }
    case actions.RECEIVE_PROJECTS:
      const projects = action.projects
      let order = itemsOrder(projects, state.sortBy, state.sortAsc)
      return {
        ...state,
        fetching: false,
        items: projects,
        order
      }
    case actions.NEXT_PROJECTS_PAGE:
      return nextPage(state)
    case actions.PREVIOUS_PROJECTS_PAGE:
      return previousPage(state)
    case actions.SORT_PROJECTS:
      return sortItems(state, action)
    default:
      return state
  }
}
