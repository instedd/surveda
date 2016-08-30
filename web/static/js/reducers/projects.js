import { combineReducers }  from 'redux'
import * as actions from '../actions/projects'
import merge from 'lodash/merge'
import union from 'lodash/union'

const projects = (state = {}, action) => {
  switch (action.type) {
    case actions.CREATE_PROJECT:
    case actions.UPDATE_PROJECT:
      return {
        ...state,
        [action.id]: {
          ...action.project
        }
      }
    case actions.FETCH_PROJECTS_SUCCESS:
    default:
      if (action.response && action.response.entities) {
        return merge({}, state, action.response.entities.projects)
      }
      return state
  }
}

const ids = (state = [], action) => {
    switch (action.type) {
      case actions.CREATE_PROJECT:
        return [...state, action.id]
      case actions.FETCH_PROJECTS_SUCCESS:
        return union(state, action.response.result)
      case actions.UPDATE_PROJECT:
      default:
        return state
    }
  }

export default combineReducers({
  ids,
  projects
});
