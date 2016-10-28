import * as actions from '../actions/respondents'

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
    case actions.REMOVE_RESPONDENTS:
      return {}
    case actions.INVALID_RESPONDENTS:
      return {
        ...state,
        invalidRespondents: action.invalidRespondents
      }
    case actions.CLEAR_INVALIDS:
      const newState = Object.assign({}, state)
      delete newState.invalidRespondents
      return newState
    default:
      return state
  }
}
