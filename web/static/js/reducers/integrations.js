import * as actions from '../actions/integrations'

const initialState = {
  fetching: false,
  items: null,
  order: [],
  surveyId: null,
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.FETCH: return fetchIntegrations(state, action)
    case actions.CREATE: return createOrUpdateIntegration(state, action)
    case actions.UPDATE: return createOrUpdateIntegration(state, action)
    case actions.RECEIVE: return receiveIntegrations(state, action)
    default: return state
  }
}

const fetchIntegrations = (state, action) => {
  const sameSurvey = state.surveyId == action.surveyId

  const items = sameSurvey ? state.items : null
  return {
    ...state,
    items,
    fetching: true,
    surveyId: action.surveyId
  }
}

const createOrUpdateIntegration = (state, action) => ({
  ...state,
  [action.id]: {
    ...action.integration
  }
})

const receiveIntegrations = (state, action) => {
  if (state.surveyId != action.surveyId) {
    return state
  }

  return {
    ...state,
    fetching: false,
    items: action.items
  }
}
