import { combineReducers } from 'redux'
import * as actions from '../actions/respondents'
import merge from 'lodash/merge'

export default (state = {}, action) => {
  switch (action.type) {
    case actions.RECEIVE_RESPONDENTS_STATS:
      return {
        ...state,
        [action.surveyId]: {
          ...action.respondentsStats
        }
      }
    default:
      return state
  }
}
