import * as actions from '../actions/survey'

export default (state = {}, action) => {
  switch (action.type) {
    case actions.RECEIVE_SURVEY_STATS:
      return {
        ...state,
        surveyId: action.surveyId,
        stats: action.response
      }
    default:
      return state
  }
}
