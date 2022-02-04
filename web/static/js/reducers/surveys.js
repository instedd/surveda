// @flow
import * as actions from '../actions/surveys'
import collectionReducer, { projectFilterProvider } from './collection'

const itemsReducer = (items: IndexedList<Survey>, action): IndexedList<Survey> => {
  switch (action.type) {
    case actions.DELETED:
      return removeItem(items, action.id)
    case actions.FOLDER_CHANGED:
      return removeItem(items, action.surveyId)
    default:
      return items
  }
}

function removeItem(items: IndexedList<Survey>, surveyId: number) {
  if (items[surveyId]) {
    items = {...items}
    delete items[surveyId]
  }
  return items
}

const initialState = {
  fetching: false,
  filter: null,
  items: null,
  order: null,
  sortBy: null,
  sortAsc: true,
  page: {
    index: 0,
    size: 15
  }
}

export default collectionReducer(actions, itemsReducer, projectFilterProvider, initialState)
