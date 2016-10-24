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
    case actions.FETCH_QUESTIONNAIRES:
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
    case actions.CREATE_QUESTIONNAIRE:
    case actions.UPDATE_QUESTIONNAIRE:
      return {
        ...state,
        [action.id]: {
          ...action.questionnaire
        }
      }
    case actions.RECEIVE_QUESTIONNAIRES:
      const questionnaires = action.questionnaires

      if (state.projectId !== action.projectId) {
        return state
      }

      let order = itemsOrder(questionnaires, state.sortBy, state.sortAsc)
      return {
        ...state,
        fetching: false,
        items: questionnaires,
        order
      }
    case actions.NEXT_QUESTIONNAIRES_PAGE:
      return nextPage(state)
    case actions.PREVIOUS_QUESTIONNAIRES_PAGE:
      return previousPage(state)
    case actions.SORT_QUESTIONNAIRES:
      return sortItems(state, action)
    default:
      return state
  }
}
