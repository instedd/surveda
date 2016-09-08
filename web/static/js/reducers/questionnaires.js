import { combineReducers } from 'redux'
import * as actions from '../actions/questionnaires'
import merge from 'lodash/merge'

export default (state = {}, action) => {
  switch (action.type) {
    case actions.CREATE_QUESTIONNAIRE:
    case actions.UPDATE_QUESTIONNAIRE:
      return {
        ...state,
        [action.id]: {
          ...action.questionnaire
        }
      }
    case actions.RECEIVE_QUESTIONNAIRES:
      if (action.response && action.response.entities) {
        return action.response.entities.questionnaires || {}
      }
      return state
    default:
      return state
  }
}
