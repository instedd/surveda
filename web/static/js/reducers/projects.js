import { combineReducers } from 'redux'
import * as actions from '../actions/projects'
import merge from 'lodash/merge'

export default (state = {}, action) => {
  switch (action.type) {
    case actions.CREATE_PROJECT:
    case actions.UPDATE_PROJECT:
      return {
        ...state,
        [action.id]: {
          ...action.project
        }
      }
    case actions.RECEIVE_PROJECTS:
      if (action.response && action.response.entities) {
        return action.response.entities.projects || {}
      }
      return state
    default:
      return state
  }
}
