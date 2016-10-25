import * as api from '../api'
import isEqual from 'lodash/isEqual'

export const CHANGE_CUTOFF = 'SURVEY_EDITOR_CHANGE_CUTOFF'
export const CHANGE_QUESTIONNAIRE = 'SURVEY_EDITOR_CHANGE_QUESTIONNAIRE'
export const INITIALIZE_EDITOR = 'SURVEY_EDITOR_INITIALIZE_EDITOR'
export const TOGGLE_DAY = 'SURVEY_EDITOR_TOGGLE_DAY'
export const SET_SCHEDULE_TO = 'SET_SCHEDULE_TO'
export const SET_SCHEDULE_FROM = 'SET_SCHEDULE_FROM'
export const SELECT_CHANNELS = 'SELECT_CHANNELS'
export const UPDATE_RESPONDENTS_COUNT = 'UPDATE_RESPONDENTS_COUNT'
export const SET_STATE = 'SET_STATE'
export const SET_SURVEY = 'SET_SURVEY'
export const FETCH = 'FETCH'
export const RECEIVE = 'RECEIVE'

export const fetchSurvey = (projectId, id) => (dispatch, getState) => {
  dispatch(fetching(projectId, id))
  return api.fetchSurvey(projectId, id)
    .then(response => {
      dispatch(receive(response.entities.surveys[response.result]))
    })
    .then(() => {
      getState().survey.data
    })
}

export const fetching = (projectId, id) => ({
  type: FETCH,
  id,
  projectId
})

export const fetch = (projectId, id) => {
  return (dispatch, getState) => {
    if (shouldFetch(getState().survey, projectId, id)) {
      return dispatch(fetchSurvey(projectId, id))
    } else {
      return Promise.resolve(getState().survey.data)
    }
  }
}

export const receive = (survey) => ({
  type: RECEIVE,
  survey
})

export const shouldFetch = (state, projectId, id) => {
  return !state.fetching || !(state.filter && (state.filter.projectId == projectId && state.filter.id == id))
}

export const setSurvey = (response) => ({
  type: SET_SURVEY,
  id: response.result,
  survey: response.entities.surveys[response.result]
})

export const changeCutoff = (cutoff) => ({
  type: CHANGE_CUTOFF,
  cutoff
})

export const toggleDay = (day) => ({
  type: TOGGLE_DAY,
  day
})

export const setState = (state) => ({
  type: SET_STATE,
  state
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
