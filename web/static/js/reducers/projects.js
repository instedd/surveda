import * as actions from '../actions/projects'

const initialState = {
  fetching: false,
  items: null,
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
      return {
        ...state,
        fetching: false,
        items: action.projects
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
      const sortAsc = state.sortBy == action.property ? !state.sortAsc : true
      return {
        ...state,
        sortBy: action.property,
        sortAsc
      }
    default:
      return state
  }
}
