// @flow
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

export default (state: SurveyList = initialState, action: any) => {
  switch (action.type) {
    case actions.FETCH: return fetchSurveys(state, action)
    case actions.RECEIVE: return receiveSurveys(state, action)
    case actions.NEXT_PAGE: return nextPage(state)
    case actions.PREVIOUS_PAGE: return previousPage(state)
    case actions.SORT: return sortItems(state, action)
    default: return state
  }
}

const fetchSurveys = (state, action) => {
  const items = state.projectId == action.projectId ? state.items : null
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

const receiveSurveys = (state, action) => {
  const surveys = action.surveys

  if (state.projectId != action.projectId) {
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
