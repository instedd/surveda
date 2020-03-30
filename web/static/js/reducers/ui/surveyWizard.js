import * as actions from '../../actions/ui'
import * as surveyActions from '../../actions/survey'
import { sumQuotasIfValid, getQuotasTotal } from '../survey'

const initialState = {
  primaryModeSelected: null,
  fallbackModeSelected: null,
  allowBlockedDays: false,
  cutOffConfig: 'default'
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.SURVEY_COMPARISON_SELECT_PRIMARY: return selectPrimaryComparison(state, action)
    case actions.SURVEY_COMPARISON_SELECT_FALLBACK: return selectFallbackComparison(state, action)
    case actions.SURVEY_ADD_COMPARISON_MODE: return resetMode(state, action)
    case actions.SURVEY_TOGGLE_BLOCKED_DAYS: return toggleBlockedDays(state, action)
    case actions.SURVEY_SET_CUTOFF_CONFIG: return surveyCutOffConfig(state, action)
    case actions.SET_INITIAL_CUTOFF_CONFIG: return setInitialCutOffConfig(state, action)
    case actions.SURVEY_CUTOFF_CONFIG_VALID: return surveyCutOffConfigValid(state, action)
    case surveyActions.RECEIVE: return setBlockedDays(state, action)
    default: return state
  }
}

const surveyCutOffConfig = (state, action) => {
  const cutOffConfigValid = action.config == 'default'
  return {
    ...state,
    cutOffConfig: action.config,
    cutOffConfigValid
  }
}

const surveyCutOffConfigValid = (state, action) => {
  let cutOffConfigValid = false
  let quotasSum
  switch (action.config) {
    case 'cutoff':
      cutOffConfigValid = action.nextValue > 0
      break
    case 'quota':
      quotasSum = sumQuotasIfValid(action.nextValue.condition, action.nextValue.buckets, action.nextValue.onlyNumbers)
      cutOffConfigValid = quotasSum > 0
      break
  }

  return {
    ...state,
    cutOffConfigValid,
    quotasSum
  }
}

const setInitialCutOffConfig = (state, action) => {
  const survey = action.survey
  const hasQuotaBuckets = survey.quotas.buckets.length > 0
  const hasCutoff = survey.cutoff !== null && !hasQuotaBuckets
  let cutOffConfigValid = true
  let quotasSum
  if (hasQuotaBuckets) {
    initialState.cutOffConfig = 'quota'
    quotasSum = getQuotasTotal(survey.quotas.buckets)
    if (!hasQuotaBuckets || !quotasSum) {
      cutOffConfigValid = false
    }
  } else {
    if (hasCutoff) {
      initialState.cutOffConfig = 'cutoff'
      if (survey.cutoff <= 0) {
        cutOffConfigValid = false
      }
    }
  }

  return {
    ...state,
    cutOffConfig: initialState.cutOffConfig,
    cutOffConfigValid,
    quotasSum
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
