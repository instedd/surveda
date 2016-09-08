import { combineReducers } from 'redux'
import * as actions from '../actions/surveys'
import merge from 'lodash/merge'

export default (state = {}, action) => {
  switch (action.type) {
    case actions.CREATE_SURVEY:
    case actions.UPDATE_SURVEY:
      return {
        ...state,
        [action.id]: {
          ...action.survey
        }
      }
    case actions.RECEIVE_SURVEYS:
      if (action.response && action.response.entities) {
        return action.response.entities.surveys || {}
      }
      return state
    default:
      return state
  }
}
