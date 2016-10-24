import * as actions from '../actions/surveys'
import { itemsOrder, sortItems, nextPage, previousPage } from '../dataTable'

const initialState = {
  fetching: false,
  projectId: null,
  items: null,
  order: null,
  sortBy: null,
  sortAsc: true,
  page: {
    index: 0,
    size: 5
  }
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.FETCH_SURVEYS: return fetchSurveys(state, action)
    case actions.SET_SURVEY: return setSurvey(state, action)
    case actions.RECEIVE_SURVEYS: return receiveSurveys(state, action)
    case actions.NEXT_SURVEYS_PAGE: return nextPage(state)
    case actions.PREVIOUS_SURVEYS_PAGE: return previousPage(state)
    case actions.SORT_SURVEYS: return sortItems(state, action)
    default: return state
  }
}

const fetchSurveys = (state, action) => {
  const items = state.projectId === action.projectId ? state.items : null
  return {
    ...state,
    items,
    fetching: true,
    projectId: action.projectId,
    sortBy: null,
    sortAsc: true,
    page: {
      index: 0,
      size: 5
    }
  }
}

const setSurvey = (state, action) => ({
  ...state,
  [action.id]: {
    ...action.survey
  }
})

const receiveSurveys = (state, action) => {
  const surveys = action.surveys

  if (state.projectId !== action.projectId) {
    return state
  }

  let order = itemsOrder(surveys, state.sortBy, state.sortAsc)
  return {
    ...state,
    fetching: false,
    items: surveys,
    order
  }
}

