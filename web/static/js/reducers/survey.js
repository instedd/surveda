import * as actions from '../actions/survey'
import fetchReducer from './fetch'

export const dataReducer = (state, action) => {
  switch (action.type) {
    case actions.CHANGE_NAME: return changeName(state, action)
    case actions.CHANGE_CUTOFF: return changeCutoff(state, action)
    case actions.CHANGE_QUESTIONNAIRE: return changeQuestionnaire(state, action)
    case actions.TOGGLE_DAY: return toggleDay(state, action)
    case actions.SET_SCHEDULE_TO: return setScheduleTo(state, action)
    case actions.SET_SCHEDULE_FROM: return setScheduleFrom(state, action)
    case actions.SELECT_CHANNELS: return selectChannels(state, action)
    case actions.SELECT_MODE: return selectMode(state, action)
    case actions.UPDATE_RESPONDENTS_COUNT: return updateRespondentsCount(state, action)
    case actions.SET_STATE: return setState(state, action)
    case actions.SET_TIMEZONE: return setTimezone(state, action)
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

const saved = (state, action) => {
  return {
    ...state,
    state: action.data.state
  }
}

const changeQuestionnaire = (state, action) => {
  return {
    ...state,
    questionnaireId: action.questionnaire
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
