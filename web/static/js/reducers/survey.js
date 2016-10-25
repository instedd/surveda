import isEqual from 'lodash/isEqual'
import * as actions from '../actions/survey'

const initialState = {
  fetching: false,
  filter: null,
  data: null
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.FETCH: return fetch(state, action)
    case actions.RECEIVE: return receive(state, action)
    default: return {
      ...state,
      data: surveyReducer(state.data, action)
    }
  }
}

const receive = (state, action) => {
  const survey = action.survey
  const filter = state.filter

  return do {
    if (filter.projectId == survey.projectId && filter.id == survey.id) {
      ({
        ...state,
        fetching: false,
        data: survey
      })
    } else {
      state
    }
  }
}

const fetch = (state, action) => {
  const newFilter = {
    projectId: action.projectId,
    id: action.id
  }

  const newData = do {
    if (isEqual(state.filter, newFilter)) {
      state.data
    } else {
      initialState.data
    }
  }

  return {
    ...state,
    fetching: true,
    filter: newFilter,
    data: newData
  }
}

export const surveyReducer = (state, action) => {
  switch (action.type) {
    case actions.CHANGE_CUTOFF: return changeCutoff(state, action)
    case actions.CHANGE_QUESTIONNAIRE: return changeQuestionnaire(state, action)
    case actions.INITIALIZE_EDITOR: return initializeEditor(state, action)
    case actions.TOGGLE_DAY: return toggleDay(state, action)
    case actions.SET_SCHEDULE_TO: return setScheduleTo(state, action)
    case actions.SET_SCHEDULE_FROM: return setScheduleFrom(state, action)
    case actions.SELECT_CHANNELS: return selectChannels(state, action)
    case actions.UPDATE_RESPONDENTS_COUNT: return updateRespondentsCount(state, action)
    case actions.SET_STATE: return setState(state, action)
    default: return state
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

const setScheduleTo = (state, action) => {
  return {
    ...state,
    scheduleEndTime: action.hour
  }
}

const updateRespondentsCount = (state, action) => {
  return {
    ...state,
    respondentsCount: action.respondentsCount
  }
}

const initializeEditor = (state, action) => {
  return action.survey
}
