import * as actions from '../../actions/ui'
import * as surveyActions from '../../actions/survey'

const initialState = {
  primaryModeSelected: null,
  fallbackModeSelected: null,
  allowBlockedDays: false
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.SURVEY_COMPARISON_SELECT_PRIMARY: return selectPrimaryComparison(state, action)
    case actions.SURVEY_COMPARISON_SELECT_FALLBACK: return selectFallbackComparison(state, action)
    case actions.SURVEY_ADD_COMPARISON_MODE: return resetMode(state, action)
    case actions.SURVEY_TOGGLE_BLOCKED_DAYS: return toggleBlockedDays(state, action)
    case surveyActions.RECEIVE: return setBlockedDays(state, action)
    default: return state
  }
}

const selectPrimaryComparison = (state, action) => {
  return {
    ...state,
    primaryModeSelected: action.mode
  }
}

const selectFallbackComparison = (state, action) => {
  return {
    ...state,
    fallbackModeSelected: action.mode
  }
}

const resetMode = (state, action) => {
  return {
    ...state,
    primaryModeSelected: null,
    fallbackModeSelected: null
  }
}

const toggleBlockedDays = (state, action) => {
  return {
    ...state,
    allowBlockedDays: !state.allowBlockedDays
  }
}

const setBlockedDays = (state, action) => {
  return {
    ...state,
    allowBlockedDays: action.data.schedule && action.data.schedule.blockedDays.length != 0
  }
}
