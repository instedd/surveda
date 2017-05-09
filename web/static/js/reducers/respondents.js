import * as actions from '../actions/respondents'

const initialState = {
  fetching: false,
  items: null,
  order: [],
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
    case actions.SORT: return sortRespondents(state, action)
    default: return state
  }
}

const fetchRespondents = (state, action) => {
  const sameSurvey = state.surveyId == action.surveyId

  const items = sameSurvey ? state.items : null
  return {
    ...state,
    items,
    fetching: true,
    surveyId: action.surveyId,
    sortBy: sameSurvey ? state.sortBy : null,
    sortAsc: sameSurvey ? state.sortAsc : true,
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

  return {
    ...state,
    fetching: false,
    items: action.respondents,
    order: action.order,
    page: {
      ...state.page,
      number: action.page,
      totalCount: action.respondentsCount
    }
  }
}

const sortRespondents = (state, action) => {
  const sortAsc = state.sortBy == action.property ? !state.sortAsc : true
  const sortBy = action.property
  return {
    ...state,
    page: {
      ...state.page,
      number: 1
    },
    sortBy,
    sortAsc
  }
}
