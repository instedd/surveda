// @flow
import * as actions from '../actions/projects'
import collectionReducer, { defaultFilterProvider } from './collection'

const itemsReducer = (state: IndexedList<Project>, action): IndexedList<Project> => {
  switch (action.type) {
    case actions.REMOVED: return removeItem(state, action)
    default: return state
  }
}

const removeItem = (state: IndexedList<Project>, action: any) => {
  const items = {...state}
  delete items[action.id]
  return items
}

const initialState = {
  fetching: false,
  items: null,
  filter: null,
  order: null,
  sortBy: 'updatedAt',
  sortAsc: false,
  page: {
    index: 0,
    size: 5
  }
}

export default collectionReducer(actions, itemsReducer, defaultFilterProvider, initialState)
