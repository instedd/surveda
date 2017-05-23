import * as actions from '../../actions/ui'

const initialState = {
  primaryModeSelected: null,
  fallbackModeSelected: null
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.SURVEY_COMPARISON_SELECT_PRIMARY: return selectPrimaryComparison(state, action)
    case actions.SURVEY_COMPARISON_SELECT_FALLBACK: return selectFallbackComparison(state, action)
    case actions.SURVEY_ADD_COMPARISON_MODE: return resetMode(state, action)
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
