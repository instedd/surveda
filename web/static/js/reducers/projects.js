import * as actions from '../actions/projects'
import values from 'lodash/values'

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
      let order = projectsOrder(projects, state.sortBy, state.sortAsc)
      return {
        ...state,
        fetching: false,
        items: projects,
        order
      }
    case actions.NEXT_PROJECTS_PAGE:
      return {
        ...state,
        page: {
          ...state.page,
          index: state.page.index + state.page.size
        }
      }
    case actions.PREVIOUS_PROJECTS_PAGE:
      return {
        ...state,
        page: {
          ...state.page,
          index: state.page.index - state.page.size
        }
      }
    case actions.SORT_PROJECTS:
      const sortAsc = state.sortBy === action.property ? !state.sortAsc : true
      const sortBy = action.property
      order = projectsOrder(state.items, sortBy, sortAsc)
      return {
        ...state,
        order,
        sortBy,
        sortAsc
      }
    default:
      return state
  }
}

const projectsOrder = (items, sortBy, sortAsc) => {
  const projects = values(items)

  if (sortBy) {
    projects.sort((p1, p2) => {
      let x1 = p1[sortBy]
      let x2 = p2[sortBy]

      if (typeof (x1) === 'string') x1 = x1.toLowerCase()
      if (typeof (x2) === 'string') x2 = x2.toLowerCase()

      if (x1 < x2) {
        return sortAsc ? -1 : 1
      } else if (x1 > x2) {
        return sortAsc ? 1 : -1
      } else {
        return 0
      }
    })
  }

  return projects.map(p => p.id)
}
