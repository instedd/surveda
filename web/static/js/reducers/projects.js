import * as actions from '../actions/projects'

const initialState = {
  fetching: false,
  items: null
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.FETCH_PROJECTS:
      return {
        ...state,
        fetching: true
      }
    case actions.RECEIVE_PROJECTS:
      return {
        ...state,
        fetching: false,
        items: action.projects
      }
    default:
      return state
  }
}
