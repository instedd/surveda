import * as actions from '../actions/respondents'

const initialState = {
  fetching: false,
  items: null,
  surveyId: null,
  sortBy: null,
  sortAsc: true,
  page: {
    number: 1,
    size: 5,
    totalCount: 0
  }
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.FETCH_RESPONDENTS: return fetchRespondents(state, action)
    case actions.CREATE_RESPONDENT: return createOrUpdateRespondent(state, action)
    case actions.UPDATE_RESPONDENT: return createOrUpdateRespondent(state, action)
    case actions.RECEIVE_RESPONDENTS: return receiveRespondents(state, action)
    case actions.REMOVE_RESPONDENTS: return removeRespondents(state, action)
    case actions.INVALID_RESPONDENTS: return receiveInvalids(state, action)
    case actions.CLEAR_INVALIDS: return clearInvalids(state, action)
    default: return state
  }
}

const fetchRespondents = (state, action) => {
  const items = state.surveyId == action.surveyId ? state.items : null
  return {
    ...state,
    items,
    fetching: true,
    surveyId: action.surveyId,
    sortBy: null,
    sortAsc: true,
    page: {
      ...state.page,
      number: action.page
    }
  }
}

const createOrUpdateRespondent = (state, action) => ({
  ...state,
  [action.id]: {
    ...action.respondent
  }
})

const receiveRespondents = (state, action) => {
  if (state.surveyId != action.surveyId || state.page.number != action.page) {
    return state
  }

  const respondents = action.respondents
  return {
    ...state,
    fetching: false,
    items: respondents,
    page: {
      ...state.page,
      number: action.page,
      totalCount: action.respondentsCount
    }
  }
}

const removeRespondents = (state, action) => ({
  ...state,
  page: {
    ...state.page,
    totalCount: 0
  }
})

const receiveInvalids = (state, action) => ({
  ...state,
  invalidRespondents: action.invalidRespondents
})

const clearInvalids = (state, action) => {
  const newState = Object.assign({}, state)
  delete newState.invalidRespondents
  return newState
}
