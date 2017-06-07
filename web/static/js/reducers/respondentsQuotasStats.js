import * as actions from '../actions/respondents'

export default (state = {}, action) => {
  switch (action.type) {
    case actions.RECEIVE_RESPONDENTS_QUOTAS_STATS:
      return {
        ...state,
        ...action.response
      }
    default:
      return state
  }
}
