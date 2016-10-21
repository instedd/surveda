import * as actions from '../actions/survey'

export default (state = {}, action) => {
  switch (action.type) {
    case actions.FETCHING_SURVEY: return fetchingSurvey(state, action)
    // case actions.INITIALIZE_EDITOR: return initializeEditor(state, action)
    default: return {
      ...state,
      filters: filtersReducer(state, action),
      data: surveyReducer(state, action),
      validations: validationsReducer(state, action)
    }
  }
}

const fetchingSurvey = (state, action) => {
  return {
    fetching: true,
    filters: filtersReducer(state, action),
    data: surveyReducer(state, action),
    validations: validationsReducer(state, action)
  }
}

const filtersReducer = (state = {}, action) => {
  switch (action.type) {
    case actions.FETCH: return fetchingSurveyFilters(state, action)
    default: return state
  }
}

const fetchingSurveyFilters = (state, {projectId, id}) => {
  return {projectId, id}
}

const validationsReducer = (state = {}, action) => {
  switch (action.type) {
    default: return state
  }
}

const surveyReducer = (state = {}, action) => {
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
