import * as actions from '../actions/project'

const initialState = {
  fetching: false,
  projectId: null,
  data: null
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.FETCH_PROJECT:
      // Keep old data while reloading the same project
      const newData = state.projectId === action.projectId ? state.data : null
      return {
        ...state,
        fetching: true,
        projectId: action.projectId,
        data: newData
      }
    case actions.RECEIVE_PROJECT:
      // Ignore if receiving a project that's not the last requested one
      if (state.projectId !== action.project.id) {
        return state
      }

      return {
        ...state,
        fetching: false,
        data: action.project
      }
    case actions.CREATE_PROJECT:
    case actions.UPDATE_PROJECT:
      return {
        ...state,
        fetching: false,
        projectId: action.project.id,
        data: action.project
      }
    case actions.CLEAR_PROJECT:
      return {
        ...state,
        fetching: false,
        projectId: null,
        data: null
      }
    default:
      return state
  }
}
