export const CHANGE_CUTOFF = 'SURVEY_EDITOR_CHANGE_CUTOFF'
export const CHANGE_QUESTIONNAIRE = 'SURVEY_EDITOR_CHANGE_QUESTIONNAIRE'
export const INITIALIZE_EDITOR = 'SURVEY_EDITOR_INITIALIZE_EDITOR'
export const TOGGLE_DAY = 'SURVEY_EDITOR_TOGGLE_DAY'
export const SET_SCHEDULE_TO = 'SET_SCHEDULE_TO'
export const SET_SCHEDULE_FROM = 'SET_SCHEDULE_FROM'
export const SELECT_CHANNELS = 'SELECT_CHANNELS'
export const UPDATE_RESPONDENTS_COUNT = 'UPDATE_RESPONDENTS_COUNT'

export const changeCutoff = (cutoff) => ({
  type: CHANGE_CUTOFF,
  cutoff
})

export const toggleDay = (day) => ({
  type: TOGGLE_DAY,
  day
})

export const setScheduleFrom = (hour) => ({
  type: SET_SCHEDULE_FROM,
  hour
})

export const selectChannels = (channels) => ({
  type: SELECT_CHANNELS,
  channels
})

export const setScheduleTo = (hour) => ({
  type: SET_SCHEDULE_TO,
  hour
})

export const changeQuestionnaire = (questionnaire) => ({
  type: CHANGE_QUESTIONNAIRE,
  questionnaire
})

export const initializeEditor = (survey) => ({
  type: INITIALIZE_EDITOR,
  survey
})

export const updateRespondentsCount = (respondentsCount) => ({
  type: UPDATE_RESPONDENTS_COUNT,
  respondentsCount
})
