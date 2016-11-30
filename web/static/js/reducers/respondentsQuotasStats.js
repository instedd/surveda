import * as actions from '../actions/respondents'

export default (state = {}, action) => {
  switch (action.type) {
    case actions.RECEIVE_RESPONDENTS_QUOTAS_STATS:
      return {
        ...state,
        data: action.data
      }
    default:
      return state
  }
}
