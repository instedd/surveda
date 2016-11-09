import * as actions from '../actions/questionnaires'
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
    case actions.FETCH_QUESTIONNAIRES: return fetchQuestionnaires(state, action)
    case actions.RECEIVE_QUESTIONNAIRES: return receiveQuestionnaires(state, action)
    case actions.NEXT_QUESTIONNAIRES_PAGE: return nextPage(state)
    case actions.PREVIOUS_QUESTIONNAIRES_PAGE: return previousPage(state)
    case actions.SORT_QUESTIONNAIRES: return sortItems(state, action)
    default: return state
  }
}

const fetchQuestionnaires = (state, action) => {
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

const receiveQuestionnaires = (state, action) => {
  const questionnaires = action.questionnaires

  if (state.projectId != action.projectId) {
    return state
  }

  let order = itemsOrder(questionnaires, state.sortBy, state.sortAsc)
  return {
    ...state,
    fetching: false,
    items: questionnaires,
    order
  }
}
