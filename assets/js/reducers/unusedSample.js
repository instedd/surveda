// @flow
import * as actions from "../actions/surveys"

const initialState = null

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.FETCHING_UNUSED_SAMPLE_SURVEYS:
      return initialState
    case actions.RECEIVE_UNUSED_SAMPLE_SURVEYS:
      return receiveUnusedSampleSurveys(state, action)
    default:
      return state
  }
}

const receiveUnusedSampleSurveys = (state: Array, action: any) => (
  {
    ...state,
    surveys: action.surveys,
  }
)

