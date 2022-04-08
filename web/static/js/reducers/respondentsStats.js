import * as actions from "../actions/respondents"

export default (state = {}, action) => {
  switch (action.type) {
    case actions.RECEIVE_RESPONDENTS_STATS:
      return {
        ...state,
        ...action.response.entities.respondents,
      }
    default:
      return state
  }
}
