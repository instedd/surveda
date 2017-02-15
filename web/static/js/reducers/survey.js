// @flow
import * as actions from '../actions/survey'
import fetchReducer from './fetch'
import drop from 'lodash/drop'
import flatten from 'lodash/flatten'
import map from 'lodash/map'
import split from 'lodash/split'
import find from 'lodash/find'
import findIndex from 'lodash/findIndex'
import isEqual from 'lodash/isEqual'
import uniqWith from 'lodash/uniqWith'
import some from 'lodash/some'

export const dataReducer = (state: Survey, action: any): Survey => {
  switch (action.type) {
    case actions.CHANGE_NAME: return changeName(state, action)
    case actions.CHANGE_CUTOFF: return changeCutoff(state, action)
    case actions.CHANGE_QUOTA: return quotaChange(state, action)
    case actions.CHANGE_COMPARISON_RATIO: return comparisonRatioChange(state, action)
    case actions.CHANGE_QUESTIONNAIRE: return changeQuestionnaire(state, action)
    case actions.TOGGLE_DAY: return toggleDay(state, action)
    case actions.SET_SCHEDULE_TO: return setScheduleTo(state, action)
    case actions.SET_SCHEDULE_FROM: return setScheduleFrom(state, action)
    case actions.SELECT_MODE: return selectMode(state, action)
    case actions.CHANGE_MODE_COMPARISON: return changeModeComparison(state, action)
    case actions.CHANGE_QUESTIONNAIRE_COMPARISON: return changeQuestionnaireComparison(state, action)
    case actions.UPDATE_RESPONDENTS_COUNT: return updateRespondentsCount(state, action)
    case actions.SET_STATE: return setState(state, action)
    case actions.SET_TIMEZONE: return setTimezone(state, action)
    case actions.SET_QUOTA_VARS: return setQuotaVars(state, action)
    case actions.CHANGE_IVR_RETRY_CONFIGURATION: return changeIvrRetryConfiguration(state, action)
    case actions.CHANGE_SMS_RETRY_CONFIGURATION: return changeSmsRetryConfiguration(state, action)
    case actions.CHANGE_FALLBACK_DELAY: return changeFallbackDelay(state, action)
    case actions.SAVED: return saved(state, action)
    default: return state
  }
}

const validateReducer = (reducer: StoreReducer<Survey>): StoreReducer<Survey> => {
  return (state: ?DataStore<Survey>, action: any) => {
    const newState = reducer(state, action)
    validate(newState)
    return newState
  }
}

export default validateReducer(fetchReducer(actions, dataReducer))

const validate = (state) => {
  state.errors = {}
  validateRetry(state, 'sms', 'smsRetryConfiguration')
  validateRetry(state, 'ivr', 'ivrRetryConfiguration')
  validateFallbackDelay(state)
}

const validateRetry = (state: DataStore<Survey>, mode, key) => {
  if (!state.data) return

  const data = state.data

  const modes = data.mode
  if (!modes) return

  // Don't validate retry configuration for a mode that's not active (#655)
  if (!some(modes, ms => some(ms, m => m == mode))) return

  const retriesValue = data[key]
  if (!retriesValue) return

  let values = retriesValue.split(' ')
  values = values.filter((v) => v)
  const invalid = values.some((v) => !timeSpecRegex.test(v))
  if (invalid) {
    state.errors[key] = ['Re-contact configuration is invalid']
  }
}

const validateFallbackDelay = (state: DataStore<Survey>) => {
  if (!state.data) return

  const data = state.data

  const modes = data.mode
  if (!modes) return

  // Don't validate fallback delay if there's no fallback mode
  if (!some(modes, ms => ms.length > 1)) return

  const fallbackDelay = data.fallbackDelay
  if (!fallbackDelay) return

  const invalid = !timeSpecRegex.test(fallbackDelay)
  if (invalid) {
    state.errors.fallbackDelay = ['Fallback delay is invalid']
  }
}

const timeSpecRegex = /^\d+[mhd]$/

const changeName = (state, action) => {
  return {
    ...state,
    name: action.newName
  }
}

const changeCutoff = (state, action) => {
  return {
    ...state,
    cutoff: action.cutoff
  }
}

const setState = (state, action) => {
  return {
    ...state,
    state: action.state
  }
}

const setQuotaVars = (state, action) => {
  return {
    ...state,
    quotas: {
      vars: map(action.vars, (storeVar) => storeVar.var),
      buckets: bucketsFor(action.vars, action.options)
    }
  }
}

const bucketsFor = (storeVars, options) => {
  if (storeVars.length == 0) {
    return []
  } else {
    return buildBuckets(storeVars, options)
  }
}

const buildBuckets = (storeVars, options) => {
  const firstVar = options[storeVars[0].var]

  let values = firstVar.values
  if (firstVar.type == 'numeric') {
    values = intervalsFrom(storeVars[0].steps)
  }

  return flatten(map(values, (value) => {
    let buckets = []
    if (drop(storeVars).length == 0) {
      buckets = [{}]
    } else {
      buckets = buildBuckets(drop(storeVars), options)
    }

    return map(buckets, (bucket) => {
      let condition = []
      if (bucket.condition && bucket.condition.length > 0) {
        condition = bucket.condition
      }

      return ({
        ...bucket,
        condition: [
          ...condition,
          {
            store: storeVars[0].var,
            value: value
          }
        ]
      })
    })
  }))
}

const intervalsFrom = (valueString) => {
  const values = map(split(valueString, ','), (value) => parseInt(value.trim()))
  if (values.length <= 1) {
    return []
  }

  return [[values[0], values[1] - 1], ...intervalsFrom(drop(values))]
}

const comparisonRatioChange = (state, action) => {
  const bucketIndex = findIndex(state.comparisons, (bucket) =>
    bucket.questionnaireId == action.questionnaireId && isEqual(bucket.mode, action.mode)
  )
  return {
    ...state,
    comparisons: [
      ...state.comparisons.slice(0, bucketIndex),
      {
        ...state.comparisons[bucketIndex],
        ratio: action.ratio
      },
      ...state.comparisons.slice(bucketIndex + 1)
    ]
  }
}

const quotaChange = (state, action) => {
  const bucketIndex = findIndex(state.quotas.buckets, (bucket) =>
    isEqual(bucket.condition, action.condition)
  )
  return {
    ...state,
    quotas: {
      ...state.quotas,
      buckets: [
        ...state.quotas.buckets.slice(0, bucketIndex),
        {
          ...state.quotas.buckets[bucketIndex],
          quota: action.quota
        },
        ...state.quotas.buckets.slice(bucketIndex + 1)
      ]
    }
  }
}

export const rebuildInputFromQuotaBuckets = (store: string, survey: Survey) => {
  const buckets = survey.quotas.buckets.filter((bucket) => bucket.condition.map((condition) => condition.store).includes(store))
  let conditions = uniqWith(buckets.map((bucket) => find(bucket.condition, (condition) => condition.store == store).value), isEqual)
  conditions = conditions.map(x => [x[0], x[1] + 1])
  conditions = flatten(conditions)
  conditions = uniqWith(conditions, isEqual)
  return conditions.join()
}

export const modeLabel = (mode: string[]) => {
  if (isEqual(mode, ['sms'])) {
    return 'SMS'
  }
  if (isEqual(mode, ['ivr'])) {
    return 'Phone call'
  }
  if (isEqual(mode, ['ivr', 'sms'])) {
    return 'Phone call with SMS fallback'
  }
  if (isEqual(mode, ['sms', 'ivr'])) {
    return 'SMS with phone call fallback'
  }
  return 'Unknown mode'
}

const saved = (state, action) => {
  return {
    ...state,
    state: action.data.state
  }
}

const changeQuestionnaire = (state, action) => {
  let questionnaireId = parseInt(action.questionnaire)

  let newQuestionnaireIds
  let questionnaireIds = state.questionnaireIds || []
  let questionnaireComparison = questionnaireIds.length > 1 || state.questionnaireComparison

  if (questionnaireComparison) {
    newQuestionnaireIds = questionnaireIds.slice()
    let index = questionnaireIds.indexOf(questionnaireId)
    if (index == -1) {
      newQuestionnaireIds.push(questionnaireId)
    } else {
      newQuestionnaireIds.splice(index, 1)
    }
  } else {
    newQuestionnaireIds = [questionnaireId]
  }

  return {
    ...state,
    questionnaireIds: newQuestionnaireIds,
    questionnaireComparison,
    comparisons: buildComparisons(state.modeComparison, questionnaireComparison, state.mode, newQuestionnaireIds),
    quotas: {
      vars: [],
      buckets: []
    }
  }
}

const toggleDay = (state, action) => {
  return {
    ...state,
    scheduleDayOfWeek: {
      ...state.scheduleDayOfWeek,
      [action.day]: !state.scheduleDayOfWeek[action.day]
    }
  }
}

const setScheduleFrom = (state, action) => {
  return {
    ...state,
    scheduleStartTime: action.hour
  }
}

const selectMode = (state, action) => {
  let newMode
  let stateMode = state.mode || []
  let modeComparison = stateMode.length > 1 || state.modeComparison

  if (modeComparison) {
    let mode = state.mode || []
    if (some(mode, m => isEqual(m, action.mode))) {
      newMode = mode.filter(m => !isEqual(m, action.mode))
    } else {
      newMode = mode.slice()
      newMode.push(action.mode)
    }
  } else {
    newMode = [action.mode]
  }

  return {
    ...state,
    mode: newMode,
    modeComparison,
    comparisons: buildComparisons(modeComparison, state.questionnaireComparison, newMode, state.questionnaireIds)
  }
}

const changeModeComparison = (state, action) => {
  let newMode = state.mode || []
  let modeComparison = newMode.length > 1 || state.modeComparison
  let newModeComparison = !modeComparison

  if (!newModeComparison) {
    if (newMode.length == 1) {
      newMode = [newMode[0]]
    } else {
      newMode = []
    }
  }

  return {
    ...state,
    mode: newMode,
    comparisons: buildComparisons(newModeComparison, state.questionnaireComparison, newMode, state.questionnaireIds),
    modeComparison: newModeComparison
  }
}

const changeQuestionnaireComparison = (state, action) => {
  let newQuestionnaireIds = state.questionnaireIds || []
  let questionnaireComparison = newQuestionnaireIds.length > 1 || state.questionnaireComparison
  let newQuestionnaireComparison = !questionnaireComparison

  if (!newQuestionnaireComparison) {
    if (newQuestionnaireIds.length == 1) {
      newQuestionnaireIds = [newQuestionnaireIds[0]]
    } else {
      newQuestionnaireIds = []
    }
  }

  return {
    ...state,
    questionnaireIds: newQuestionnaireIds,
    questionnaireComparison: newQuestionnaireComparison,
    comparisons: buildComparisons(state.modeComparison, newQuestionnaireComparison, state.mode, newQuestionnaireIds)
  }
}

const buildComparisons = (modeComparison, questionnaireComparison, modes, questionnaires) => {
  if ((modeComparison || questionnaireComparison) && modes && questionnaires) {
    return flatten(map(modes, (mode) => {
      return map(questionnaires, (questionnaire) => {
        return ({
          mode: mode,
          questionnaireId: questionnaire
        })
      })
    }))
  } else {
    return []
  }
}

const setScheduleTo = (state, action) => {
  return {
    ...state,
    scheduleEndTime: action.hour
  }
}

const setTimezone = (state, action) => {
  return {
    ...state,
    timezone: action.timezone
  }
}

const updateRespondentsCount = (state, action) => {
  return {
    ...state,
    respondentsCount: action.respondentsCount
  }
}

const changeSmsRetryConfiguration = (state, action) => {
  return {
    ...state,
    smsRetryConfiguration: action.smsRetryConfiguration
  }
}

const changeIvrRetryConfiguration = (state, action) => {
  return {
    ...state,
    ivrRetryConfiguration: action.ivrRetryConfiguration
  }
}

const changeFallbackDelay = (state, action) => {
  return {
    ...state,
    fallbackDelay: action.fallbackDelay
  }
}
