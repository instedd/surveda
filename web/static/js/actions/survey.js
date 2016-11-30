import * as api from '../api'
import find from 'lodash/find'
import each from 'lodash/each'
import map from 'lodash/map'

export const CHANGE_CUTOFF = 'SURVEY_CHANGE_CUTOFF'
export const CHANGE_QUOTA = 'SURVEY_CHANGE_QUOTA'
export const CHANGE_QUESTIONNAIRE = 'SURVEY_CHANGE_QUESTIONNAIRE'
export const CHANGE_NAME = 'SURVEY_CHANGE_NAME'
export const TOGGLE_DAY = 'SURVEY_TOGGLE_DAY'
export const SET_SCHEDULE_TO = 'SURVEY_SET_SCHEDULE_TO'
export const SET_SCHEDULE_FROM = 'SURVEY_SET_SCHEDULE_FROM'
export const SELECT_CHANNELS = 'SURVEY_SELECT_CHANNELS'
export const SELECT_MODE = 'SURVEY_SELECT_MODE'
export const UPDATE_RESPONDENTS_COUNT = 'SURVEY_UPDATE_RESPONDENTS_COUNT'
export const SET_STATE = 'SURVEY_SURVEY_SET_STATE'
export const FETCH = 'SURVEY_FETCH'
export const RECEIVE = 'SURVEY_RECEIVE'
export const SAVING = 'SURVEY_SAVING'
export const SAVED = 'SURVEY_SAVED'
export const SET_TIMEZONE = 'SURVEY_SET_TIMEZONE'
export const SET_QUOTA_VARS = 'SURVEY_SET_QUOTA_VARS'
export const CHANGE_SMS_RETRY_CONFIGURATION = 'SURVEY_CHANGE_SMS_RETRY_CONFIGURATION'
export const CHANGE_IVR_RETRY_CONFIGURATION = 'SURVEY_CHANGE_IVR_RETRY_CONFIGURATION'

export const createSurvey = (projectId) => (dispatch, getState) =>
  api.createSurvey(projectId).then(response => {
    const survey = response.result
    dispatch(fetch(projectId, survey.id))
    dispatch(receive(survey))
    return survey
  })

export const fetchSurvey = (projectId, id) => (dispatch, getState) => {
  dispatch(fetch(projectId, id))
  return api.fetchSurvey(projectId, id)
    .then(response => {
      dispatch(receive(response.entities.surveys[response.result]))
    })
    .then(() => {
      return getState().survey.data
    })
}

export const fetch = (projectId, id) => ({
  type: FETCH,
  id,
  projectId
})

export const fetchSurveyIfNeeded = (projectId, id) => (dispatch, getState) => {
  if (shouldFetch(getState().survey, projectId, id)) {
    return dispatch(fetchSurvey(projectId, id))
  } else {
    return Promise.resolve(getState().survey.data)
  }
}

export const receive = (survey) => ({
  type: RECEIVE,
  data: survey
})

export const shouldFetch = (state, projectId, id) => {
  return !state.fetching || !(state.filter && (state.filter.projectId == projectId && state.filter.id == id))
}

export const changeCutoff = (cutoff) => ({
  type: CHANGE_CUTOFF,
  cutoff
})

export const quotaChange = (condition, quota) => ({
  type: CHANGE_QUOTA,
  condition,
  quota
})

export const toggleDay = (day) => ({
  type: TOGGLE_DAY,
  day
})

export const setQuotaVars = (vars, questionnaire) => ({
  type: SET_QUOTA_VARS,
  vars,
  options: valuesFrom(vars, questionnaire)
})

const valuesFrom = (storeVars, questionnaire) => {
  let options = {}
  each(storeVars, (storeVar) => {
    const step = find(questionnaire.steps, (step) =>
        step.store == storeVar
      )
    options[storeVar] = map(step.choices, (choice) =>
      choice.value
    )
  })
  return options
}

export const setState = (state) => ({
  type: SET_STATE,
  state
})

export const changeName = (newName) => ({
  type: CHANGE_NAME,
  newName
})

export const setScheduleFrom = (hour) => ({
  type: SET_SCHEDULE_FROM,
  hour
})

export const selectChannels = (channels) => ({
  type: SELECT_CHANNELS,
  channels
})

export const selectMode = (mode) => ({
  type: SELECT_MODE,
  mode
})

export const setScheduleTo = (hour) => ({
  type: SET_SCHEDULE_TO,
  hour
})

export const changeQuestionnaire = (questionnaire) => ({
  type: CHANGE_QUESTIONNAIRE,
  questionnaire
})

export const updateRespondentsCount = (respondentsCount) => ({
  type: UPDATE_RESPONDENTS_COUNT,
  respondentsCount
})

export const setTimezone = (timezone) => ({
  type: SET_TIMEZONE,
  timezone
})

export const changeSmsRetryConfiguration = (smsRetryConfiguration) => ({
  type: CHANGE_SMS_RETRY_CONFIGURATION,
  smsRetryConfiguration
})

export const changeIvrRetryConfiguration = (ivrRetryConfiguration) => ({
  type: CHANGE_IVR_RETRY_CONFIGURATION,
  ivrRetryConfiguration
})

export const saving = () => ({
  type: SAVING
})

export const saved = (survey) => ({
  type: SAVED,
  data: survey
})

export const save = () => (dispatch, getState) => {
  const survey = getState().survey.data
  dispatch(saving())
  api.updateSurvey(survey.projectId, survey)
    .then(response => {
      return dispatch(saved(response.entities.surveys[response.result]))
    })
}
