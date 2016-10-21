import * as actions from '../actions/respondents'

export default (state = {}, action) => {
  switch (action.type) {
    case actions.CREATE_RESPONDENT:
    case actions.UPDATE_RESPONDENT:
      return 1
    case actions.RECEIVE_RESPONDENTS:
      if (action.response) {
        return action.response.respondentsCount
      }
      return state
    case actions.REMOVE_RESPONDENTS:
      return 0
    default:
      return state
  }
}
