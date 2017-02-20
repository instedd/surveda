// @flow
import * as api from '../api'
import each from 'lodash/each'
import { stepStoreValues } from '../reducers/questionnaire'
import * as surveysActions from './surveys'

export const CHANGE_CUTOFF = 'SURVEY_CHANGE_CUTOFF'
export const CHANGE_QUOTA = 'SURVEY_CHANGE_QUOTA'
export const CHANGE_COMPARISON_RATIO = 'SURVEY_CHANGE_COMPARISON_RATIO'
export const CHANGE_QUESTIONNAIRE = 'SURVEY_CHANGE_QUESTIONNAIRE'
export const CHANGE_NAME = 'SURVEY_CHANGE_NAME'
export const TOGGLE_DAY = 'SURVEY_TOGGLE_DAY'
export const SET_SCHEDULE_TO = 'SURVEY_SET_SCHEDULE_TO'
export const SET_SCHEDULE_FROM = 'SURVEY_SET_SCHEDULE_FROM'
export const SELECT_MODE = 'SURVEY_SELECT_MODE'
export const CHANGE_MODE_COMPARISON = 'SURVEY_CHANGE_MODE_COMPARISON'
export const CHANGE_QUESTIONNAIRE_COMPARISON = 'SURVEY_CHANGE_QUESTIONNAIRE_COMPARISON'
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
export const CHANGE_FALLBACK_DELAY = 'SURVEY_CHANGE_FALLBACK_DELAY'

export const createSurvey = (projectId: number) => (dispatch: Function, getState: () => Store) =>
  api.createSurvey(projectId).then(response => {
    const survey = response.result
    dispatch(fetch(projectId, survey.id))
    dispatch(receive(survey))
    return survey
  })

export const fetchSurvey = (projectId: number, id: number) => (dispatch: Function, getState: () => Store): Survey => {
  dispatch(fetch(projectId, id))
  return api.fetchSurvey(projectId, id)
    .then(response => {
      dispatch(receive(response.entities.surveys[response.result]))
    })
    .then(() => {
      return getState().survey.data
    })
}

export const fetch = (projectId: number, id: number): FilteredAction => ({
  type: FETCH,
  id,
  projectId
})

export const fetchSurveyIfNeeded = (projectId: number, id: number) => (dispatch: Function, getState: () => Store): Promise<?Survey> => {
  if (shouldFetch(getState().survey, projectId, id)) {
    return dispatch(fetchSurvey(projectId, id))
  } else {
    return Promise.resolve(getState().survey.data)
  }
}

export const receive = (survey: Survey) => ({
  type: RECEIVE,
  data: survey
})

export const shouldFetch = (state: DataStore<Survey>, projectId: number, id: number) => {
  return !state.fetching || !(state.filter && (state.filter.projectId == projectId && state.filter.id == id))
}

export const changeCutoff = (cutoff: string) => ({
  type: CHANGE_CUTOFF,
  cutoff
})

export const comparisonRatioChange = (questionnaireId: number, mode: string[], ratio: number) => ({
  type: CHANGE_COMPARISON_RATIO,
  questionnaireId,
  mode,
  ratio
})

export const quotaChange = (condition: Condition[], quota: number) => ({
  type: CHANGE_QUOTA,
  condition,
  quota
})

export const toggleDay = (day: string) => ({
  type: TOGGLE_DAY,
  day
})

export const setQuotaVars = (vars: QuotaVar[], questionnaire: Questionnaire) => ({
  type: SET_QUOTA_VARS,
  vars,
  options: optionsFrom(vars, questionnaire)
})

const optionsFrom = (storeVars: QuotaVar[], questionnaire: Questionnaire) => {
  const storeValues = stepStoreValues(questionnaire)
  let options = {}

  each(storeVars, (storeVar) => {
    options[storeVar.var] = storeValues[storeVar.var]
  })
  return options
}

export const setState = (state: string) => ({
  type: SET_STATE,
  state
})

export const changeName = (newName: string) => ({
  type: CHANGE_NAME,
  newName
})

export const setScheduleFrom = (hour: string) => ({
  type: SET_SCHEDULE_FROM,
  hour
})

export const selectMode = (mode: string[]) => ({
  type: SELECT_MODE,
  mode
})

export const changeModeComparison = () => ({
  type: CHANGE_MODE_COMPARISON
})

export const changeQuestionnaireComparison = () => ({
  type: CHANGE_QUESTIONNAIRE_COMPARISON
})

export const setScheduleTo = (hour: string) => ({
  type: SET_SCHEDULE_TO,
  hour
})

export const changeQuestionnaire = (questionnaire: number) => ({
  type: CHANGE_QUESTIONNAIRE,
  questionnaire
})

export const updateRespondentsCount = (respondentsCount: string) => ({
  type: UPDATE_RESPONDENTS_COUNT,
  respondentsCount
})

export const setTimezone = (timezone: string) => ({
  type: SET_TIMEZONE,
  timezone
})

export const changeSmsRetryConfiguration = (smsRetryConfiguration: string) => ({
  type: CHANGE_SMS_RETRY_CONFIGURATION,
  smsRetryConfiguration
})

export const changeIvrRetryConfiguration = (ivrRetryConfiguration: string) => ({
  type: CHANGE_IVR_RETRY_CONFIGURATION,
  ivrRetryConfiguration
})

export const deleteSurvey = (survey: Survey) => (dispatch: Function) => {
  api.deleteSurvey(survey.projectId, survey)
    .then(response => {
      return dispatch(surveysActions.deleted(survey))
    })
}

export const changeFallbackDelay = (fallbackDelay: string) => ({
  type: CHANGE_FALLBACK_DELAY,
  fallbackDelay
})

export const saving = () => ({
  type: SAVING
})

export const saved = (survey: Survey) => ({
  type: SAVED,
  data: survey
})

export const save = () => (dispatch: Function, getState: () => Store) => {
  const survey = getState().survey.data
  if (!survey) return
  dispatch(saving())
  api.updateSurvey(survey.projectId, survey)
    .then(response => {
      return dispatch(saved(response.entities.surveys[response.result]))
    })
}
