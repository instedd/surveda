import * as actions from '../actions/survey'
import fetchReducer from './fetch'
import drop from 'lodash/drop'
import flatten from 'lodash/flatten'
import map from 'lodash/map'
import split from 'lodash/split'
import findIndex from 'lodash/findIndex'
import isEqual from 'lodash/isEqual'
import uniqWith from 'lodash/uniqWith'

export const dataReducer = (state, action) => {
  switch (action.type) {
    case actions.CHANGE_NAME: return changeName(state, action)
    case actions.CHANGE_CUTOFF: return changeCutoff(state, action)
    case actions.CHANGE_QUOTA: return quotaChange(state, action)
    case actions.CHANGE_QUESTIONNAIRE: return changeQuestionnaire(state, action)
    case actions.TOGGLE_DAY: return toggleDay(state, action)
    case actions.SET_SCHEDULE_TO: return setScheduleTo(state, action)
    case actions.SET_SCHEDULE_FROM: return setScheduleFrom(state, action)
    case actions.SELECT_CHANNELS: return selectChannels(state, action)
    case actions.SELECT_MODE: return selectMode(state, action)
    case actions.UPDATE_RESPONDENTS_COUNT: return updateRespondentsCount(state, action)
    case actions.SET_STATE: return setState(state, action)
    case actions.SET_TIMEZONE: return setTimezone(state, action)
    case actions.SET_QUOTA_VARS: return setQuotaVars(state, action)
    case actions.CHANGE_IVR_RETRY_CONFIGURATION: return changeIvrRetryConfiguration(state, action)
    case actions.CHANGE_SMS_RETRY_CONFIGURATION: return changeSmsRetryConfiguration(state, action)
    case actions.SAVED: return saved(state, action)
    default: return state
  }
}

const validateReducer = (reducer) => {
  return (state, action) => {
    const newState = reducer(state, action)
    validate(newState)
    return newState
  }
}

const validate = (state) => {
  if (!state.data) return
  state.errors = {}
  validateRetry(state, 'smsRetryConfiguration')
  validateRetry(state, 'ivrRetryConfiguration')
}

const validateRetry = (state, key) => {
  const retriesValue = state.data[key]
  if (!retriesValue) return
  let values = retriesValue.split(' ')
  values = values.filter((v) => v)
  const invalid = values.some((v) => !/^\d+[mhd]$/.test(v))
  if (invalid) {
    state.errors[key] = 'Re-contact configuration is invalid'
  }
}

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
  if (storeVars.length == 0) {
    return [{}]
  }

  const firstVar = options[storeVars[0].var]

  let values = firstVar.values
  if (firstVar.type == 'numeric') {
    values = intervalsFrom(storeVars[0].steps)
  }

  return flatten(map(values, (value) => {
    return map(buildBuckets(drop(storeVars), options), (bucket) => {
      return ({
        ...bucket,
        condition: {
          ...bucket.condition,
          [storeVars[0].var]: value
        }
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

export const rebuildInputFromQuotaBuckets = (store, survey) => {
  const buckets = survey.quotas.buckets.filter((bucket) => Object.keys(bucket.condition).includes(store))
  let conditions = uniqWith(buckets.map((bucket) => bucket.condition[store]), isEqual)
  conditions = conditions.map(x => [x[0], x[1] + 1])
  conditions = flatten(conditions)
  conditions = uniqWith(conditions, isEqual)
  return conditions.join()
}

const saved = (state, action) => {
  return {
    ...state,
    state: action.data.state
  }
}

const changeQuestionnaire = (state, action) => {
  return {
    ...state,
    questionnaireId: action.questionnaire,
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

const selectChannels = (state, action) => {
  return {
    ...state,
    channels: action.channels
  }
}

const selectMode = (state, action) => {
  return {
    ...state,
    mode: action.mode
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

export default validateReducer(fetchReducer(actions, dataReducer))
