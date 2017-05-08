// @flow weak
import * as api from '../api'
import { newMultipleChoiceStep } from '../reducers/questionnaire'

export const FETCH = 'QUESTIONNAIRE_FETCH'
export const RECEIVE = 'QUESTIONNAIRE_RECEIVE'
export const CHANGE_NAME = 'QUESTIONNAIRE_CHANGE_NAME'
export const TOGGLE_MODE = 'QUESTIONNAIRE_TOGGLE_MODE'
export const ADD_STEP = 'QUESTIONNAIRE_ADD_STEP'
export const DELETE_STEP = 'QUESTIONNAIRE_DELETE_STEP'
export const ADD_QUOTA_COMPLETED_STEP = 'QUESTIONNAIRE_ADD_QUOTA_COMPLETED_STEP'
export const MOVE_STEP = 'QUESTIONNAIRE_MOVE_STEP'
export const MOVE_STEP_TO_TOP = 'QUESTIONNAIRE_MOVE_STEP_TO_TOP'
export const CHANGE_STEP_TITLE = 'QUESTIONNAIRE_CHANGE_STEP_TITLE'
export const CHANGE_STEP_TYPE = 'QUESTIONNAIRE_CHANGE_STEP_TYPE'
export const CHANGE_STEP_PROMPT_SMS = 'QUESTIONNAIRE_CHANGE_STEP_PROMPT_SMS'
export const AUTOCOMPLETE_STEP_PROMPT_SMS = 'QUESTIONNAIRE_AUTOCOMPLETE_STEP_PROMPT_SMS'
export const AUTOCOMPLETE_STEP_PROMPT_IVR = 'QUESTIONNAIRE_AUTOCOMPLETE_STEP_PROMPT_IVR'
export const CHANGE_STEP_PROMPT_MOBILE_WEB = 'QUESTIONNAIRE_CHANGE_STEP_PROMPT_MOBILE_WEB'
export const CHANGE_STEP_PROMPT_IVR = 'QUESTIONNAIRE_CHANGE_STEP_PROMPT_IVR'
export const CHANGE_STEP_AUDIO_ID_IVR = 'QUESTIONNAIRE_CHANGE_STEP_AUDIO_ID_IVR'
export const CHANGE_STEP_STORE = 'QUESTIONNAIRE_CHANGE_STEP_STORE'
export const ADD_CHOICE = 'QUESTIONNAIRE_ADD_CHOICE'
export const DELETE_CHOICE = 'QUESTIONNAIRE_DELETE_CHOICE'
export const CHANGE_CHOICE = 'QUESTIONNAIRE_CHANGE_CHOICE'
export const AUTOCOMPLETE_CHOICE_SMS_VALUES = 'QUESTIONNAIRE_AUTOCOMPLETE_CHOICE_SMS_VALUES'
export const SAVING = 'QUESTIONNAIRE_SAVING'
export const SAVED = 'QUESTIONNAIRE_SAVED'
export const ADD_LANGUAGE = 'QUESTIONNAIRE_ADD_LANGUAGE'
export const REMOVE_LANGUAGE = 'QUESTIONNAIRE_REMOVE_LANGUAGE'
export const REORDER_LANGUAGES = 'QUESTIONNAIRE_REORDER_LANGUAGES'
export const SET_DEFAULT_LANGUAGE = 'QUESTIONNAIRE_SET_DEFAULT_LANGUAGE'
export const SET_ACTIVE_LANGUAGE = 'QUESTIONNAIRE_SET_ACTIVE_LANGUAGE'
export const SET_SMS_QUESTIONNAIRE_MSG = 'QUESTIONNAIRE_SMS_SET_QUESTIONNAIRE_MSG'
export const SET_IVR_QUESTIONNAIRE_MSG = 'QUESTIONNAIRE_IVR_SET_QUESTIONNAIRE_MSG'
export const SET_MOBILE_WEB_QUESTIONNAIRE_MSG = 'QUESTIONNAIRE_MOBILE_WEB_SET_QUESTIONNAIRE_MSG'
export const AUTOCOMPLETE_SMS_QUESTIONNAIRE_MSG = 'QUESTIONNAIRE_SMS_AUTOCOMPLETE_QUESTIONNAIRE_MSG'
export const AUTOCOMPLETE_IVR_QUESTIONNAIRE_MSG = 'QUESTIONNAIRE_IVR_AUTOCOMPLETE_QUESTIONNAIRE_MSG'
export const CHANGE_NUMERIC_RANGES = 'QUESTIONNAIRE_CHANGE_NUMERIC_RANGES'
export const CHANGE_RANGE_SKIP_LOGIC = 'QUESTIONNAIRE_CHANGE_RANGE_SKIP_LOGIC'
export const UPLOAD_CSV_FOR_TRANSLATION = 'QUESTIONNAIRE_UPLOAD_CSV_FOR_TRANSLATION'
export const CHANGE_EXPLANATION_STEP_SKIP_LOGIC = 'QUESTIONNAIRE_CHANGE_EXPLANATION_STEP_SKIP_LOGIC'
export const CHANGE_DISPOSITION = 'QUESTIONNAIRE_CHANGE_DISPOSITION'
export const TOGGLE_ACCEPT_REFUSALS = 'QUESTIONNAIRE_TOGGLE_ACCEPT_REFUSALS'
export const CHANGE_REFUSAL = 'QUESTIONNAIRE_CHANGE_REFUSAL'
export const SET_MOBILE_WEB_SMS_MESSAGE = 'QUESTIONNAIRE_SET_MOBILE_WEB_SMS_MESSAGE'
export const SET_MOBILE_WEB_SURVEY_IS_OVER_MESSAGE = 'QUESTIONNAIRE_SET_MOBILE_WEB_SURVEY_IS_OVER_MESSAGE'
export const SET_PRIMARY_COLOR = 'QUESTIONNAIRE_SET_PRIMARY_COLOR'
export const SET_SECONDARY_COLOR = 'QUESTIONNAIRE_SET_SECONDARY_COLOR'
export const SET_DISPLAYED_TITLE = 'QUESTIONNAIRE_SET_DISPLAYED_TITLE'
export const SET_SURVEY_ALREADY_TAKEN_MESSAGE = 'QUESTIONNAIRE_SET_SURVEY_ALREADY_TAKEN_MESSAGE'
export const TOGGLE_QUOTA_COMPLETED_STEPS = 'QUESTIONNAIRE_TOGGLE_QUOTA_COMPLETED_STEPS'

export const fetchQuestionnaire = (projectId, id) => (dispatch, getState) => {
  dispatch(fetch(projectId, id))
  return api.fetchQuestionnaire(projectId, id)
    .then(response => {
      let questionnaire = response.entities.questionnaires[response.result]
      dispatch(receive(questionnaire))
    })
    .then(() => {
      return getState().questionnaire.data
    })
}

export const fetch = (projectId, id): FilteredAction => ({
  type: FETCH,
  projectId,
  id
})

export const fetchQuestionnaireIfNeeded = (projectId, id) => {
  return (dispatch, getState) => {
    if (shouldFetch(getState().questionnaire, projectId, id)) {
      return dispatch(fetchQuestionnaire(projectId, id))
    } else {
      return Promise.resolve(getState().questionnaire.data)
    }
  }
}

export const receive = (questionnaire: Questionnaire): ReceiveDataAction => {
  // When we receive a questionnaire from the server, set the
  // activeLanguage property to be the same as the defaultLanguage,
  // so we don't have to do `defaultLanguage || activeLanguage` everywhere
  return {
    type: RECEIVE,
    data: {
      ...questionnaire,
      activeLanguage: questionnaire.defaultLanguage
    }
  }
}

export const shouldFetch = (state, projectId, id) => {
  return !state.fetching || !(state.filter && (state.filter.projectId == projectId && state.filter.id == id))
}

export const addChoice = (stepId) => ({
  type: ADD_CHOICE,
  stepId
})

export const changeChoice = (stepId, index, response, smsValues, ivrValues, mobilewebValues, skipLogic, autoComplete = false) => ({
  type: CHANGE_CHOICE,
  choiceChange: { index, response, smsValues, ivrValues, mobilewebValues, skipLogic, autoComplete },
  stepId
})

export const autocompleteChoiceSmsValues = (stepId, index, item) => ({
  type: AUTOCOMPLETE_CHOICE_SMS_VALUES,
  stepId,
  index,
  item
})

export const deleteChoice = (stepId, index) => ({
  type: DELETE_CHOICE,
  stepId,
  index
})

export const deleteStep = (stepId) => ({
  type: DELETE_STEP,
  stepId
})

export const changeStepStore = (stepId, newStore) => ({
  type: CHANGE_STEP_STORE,
  stepId,
  newStore
})

export const changeStepPromptSms = (stepId, newPrompt) => ({
  type: CHANGE_STEP_PROMPT_SMS,
  stepId,
  newPrompt
})

export const autocompleteStepPromptSms = (stepId, item) => ({
  type: AUTOCOMPLETE_STEP_PROMPT_SMS,
  stepId,
  item
})

export const autocompleteStepPromptIvr = (stepId, item) => ({
  type: AUTOCOMPLETE_STEP_PROMPT_IVR,
  stepId,
  item
})

export const changeStepPromptIvr = (stepId, newPrompt) => ({
  type: CHANGE_STEP_PROMPT_IVR,
  stepId,
  newPrompt
})

export const changeStepPromptMobileWeb = (stepId, newPrompt) => ({
  type: CHANGE_STEP_PROMPT_MOBILE_WEB,
  stepId,
  newPrompt
})

export const changeStepAudioIdIvr = (stepId, newId) => ({
  type: CHANGE_STEP_AUDIO_ID_IVR,
  stepId,
  newId
})

export const changeStepTitle = (stepId, newTitle) => ({
  type: CHANGE_STEP_TITLE,
  stepId,
  newTitle
})

export const changeStepType = (stepId, stepType) => ({
  type: CHANGE_STEP_TYPE,
  stepId,
  stepType
})

export const addStep = () => ({
  type: ADD_STEP
})

export const addStepWithCallback = () => (dispatch, getState) => {
  dispatch(addStep())
  const q = getState().questionnaire.data
  return Promise.resolve(q.steps[q.steps.length - 1])
}

export const addQuotaCompletedStep = () => (dispatch, getState) => {
  dispatch({
    type: ADD_QUOTA_COMPLETED_STEP
  })
  const q = getState().questionnaire.data
  return Promise.resolve(q.quotaCompletedSteps[q.quotaCompletedSteps.length - 1])
}

export const moveStep = (sourceStepId, targetStepId) => ({
  type: MOVE_STEP,
  sourceStepId,
  targetStepId
})

export const moveStepToTop = (stepId) => ({
  type: MOVE_STEP_TO_TOP,
  stepId
})

export const changeName = (newName) => ({
  type: CHANGE_NAME,
  newName
})

export const toggleMode = (mode) => ({
  type: TOGGLE_MODE,
  mode
})

export const toggleQuotaCompletedSteps = () => ({
  type: TOGGLE_QUOTA_COMPLETED_STEPS
})

export const saving = () => ({
  type: SAVING
})

export const saved = (questionnaire) => ({
  type: SAVED,
  data: questionnaire
})

export const addLanguage = (language) => ({
  type: ADD_LANGUAGE,
  language
})

export const removeLanguage = (language) => ({
  type: REMOVE_LANGUAGE,
  language
})

export const setDefaultLanguage = (language) => ({
  type: SET_DEFAULT_LANGUAGE,
  language
})

export const setActiveLanguage = (language) => ({
  type: SET_ACTIVE_LANGUAGE,
  language
})

export const reorderLanguages = (language, index) => ({
  type: REORDER_LANGUAGES,
  language,
  index
})

export const setSmsQuestionnaireMsg = (msgKey, msg) => ({
  type: SET_SMS_QUESTIONNAIRE_MSG,
  msgKey,
  msg
})

export const setIvrQuestionnaireMsg = (msgKey, msg: AudioPrompt) => ({
  type: SET_IVR_QUESTIONNAIRE_MSG,
  msgKey,
  msg
})

export const setMobileWebQuestionnaireMsg = (msgKey, msg) => ({
  type: SET_MOBILE_WEB_QUESTIONNAIRE_MSG,
  msgKey,
  msg
})

export const setDisplayedTitle = (msg) => ({
  type: SET_DISPLAYED_TITLE,
  msg
})

export const setSurveyAlreadyTakenMessage = (msg) => ({
  type: SET_SURVEY_ALREADY_TAKEN_MESSAGE,
  msg
})

export const autocompleteSmsQuestionnaireMsg = (msgKey, item) => ({
  type: AUTOCOMPLETE_SMS_QUESTIONNAIRE_MSG,
  msgKey,
  item
})

export const autocompleteIvrQuestionnaireMsg = (msgKey, item) => ({
  type: AUTOCOMPLETE_IVR_QUESTIONNAIRE_MSG,
  msgKey,
  item
})

export const save = () => (dispatch, getState) => {
  const questionnaire = getState().questionnaire.data
  dispatch(saving())
  api.updateQuestionnaire(questionnaire.projectId, questionnaire).then((response) => dispatch(saved(response.entities.questionnaires[response.result])))
}

export const createQuestionnaire = (projectId) => (dispatch) =>
  api.createQuestionnaire(projectId, {name: '', modes: ['sms', 'ivr'], steps: [newMultipleChoiceStep()], settings: {}})
  .then(response => {
    const questionnaire = response.entities.questionnaires[response.result]
    dispatch(fetch(projectId, questionnaire.id))
    dispatch(receive(questionnaire))
    return questionnaire
  })

export const duplicateQuestionnaire = (projectId, questionnaire) => (dispatch) => {
  // To duplicate a questionnaire we simply create a new
  // one with the same data as the given questionnaire,
  // except for the name
  let copy = {
    ...questionnaire,
    name: `${questionnaire.name || 'Untitled questionnaire'} (duplicate)`
  }
  return api.createQuestionnaire(projectId, copy)
  .then(response => {
    const questionnaire = response.entities.questionnaires[response.result]
    dispatch(fetch(projectId, questionnaire.id))
    dispatch(receive(questionnaire))
    return questionnaire
  })
}

export const changeNumericRanges = (stepId, minValue, maxValue, rangesDelimiters) => ({
  type: CHANGE_NUMERIC_RANGES,
  stepId,
  minValue,
  maxValue,
  rangesDelimiters
})

export const changeRangeSkipLogic = (stepId, skipLogic, rangeIndex) => ({
  type: CHANGE_RANGE_SKIP_LOGIC,
  stepId,
  rangeIndex,
  skipLogic
})

export const uploadCsvForTranslation = (csv) => ({
  type: UPLOAD_CSV_FOR_TRANSLATION,
  csv
})

export const changeExplanationStepSkipLogic = (stepId, skipLogic) => ({
  type: CHANGE_EXPLANATION_STEP_SKIP_LOGIC,
  stepId,
  skipLogic
})

export const changeDisposition = (stepId, disposition) => ({
  type: CHANGE_DISPOSITION,
  stepId,
  disposition
})

export const toggleAcceptsRefusals = (stepId) => ({
  type: TOGGLE_ACCEPT_REFUSALS,
  stepId
})

export const changeRefusal = (stepId, smsValues, ivrValues, mobilewebValues, skipLogic) => ({
  type: CHANGE_REFUSAL,
  stepId,
  smsValues,
  ivrValues,
  mobilewebValues,
  skipLogic
})

export const setMobileWebSmsMessage = (text) => ({
  type: SET_MOBILE_WEB_SMS_MESSAGE,
  text
})

export const setMobileWebSurveyIsOverMessage = (text) => ({
  type: SET_MOBILE_WEB_SURVEY_IS_OVER_MESSAGE,
  text
})

export const setPrimaryColor = (color) => ({
  type: SET_PRIMARY_COLOR,
  color
})

export const setSecondaryColor = (color) => ({
  type: SET_SECONDARY_COLOR,
  color
})
