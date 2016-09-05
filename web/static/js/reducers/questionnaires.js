import { combineReducers }  from 'redux'
import * as actions from '../actions/questionnaires'
import merge from 'lodash/merge'
import union from 'lodash/union'

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
    case actions.FETCH_QUESTIONNAIRES_SUCCESS:
      if (action.response && action.response.entities) {
        return action.response.entities.questionnaires || {}
      }
      return state
    default:
      return state

  }
}
