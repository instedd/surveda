// @flow
import * as actions from "../actions/surveys"

const initialState = null

export default (state : ?[UnusedSampleSurvey] = initialState, action: any) => {
  switch (action.type) {
    case actions.FETCHING_UNUSED_SAMPLE_SURVEYS:
      return initialState
    case actions.RECEIVE_UNUSED_SAMPLE_SURVEYS:
      return receiveUnusedSampleSurveys(state, action)
    default:
      return state
  }
}

const receiveUnusedSampleSurveys = (state: ?[UnusedSampleSurvey], action: any) => (
  action.surveys
)

