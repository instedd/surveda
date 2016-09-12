import { combineReducers } from 'redux'
import * as actions from '../actions/respondents'
import merge from 'lodash/merge'

export default (state = {}, action) => {
  switch (action.type) {
    case actions.CREATE_RESPONDENT:
    case actions.UPDATE_RESPONDENT:
      return {
        ...state,
        [action.id]: {
          ...action.respondent
        }
      }
    case actions.RECEIVE_RESPONDENTS:
      if (action.response && action.response.entities) {
        return action.response.entities.respondents || {}
      }
      return state
    default:
      return state
  }
}
