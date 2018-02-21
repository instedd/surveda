// @flow
import * as actions from '../actions/projects'
import collectionReducer from './collection'

const itemsReducer = (state: IndexedList<Project>, action): IndexedList<Project> => {
  switch (action.type) {
    case actions.REMOVE: return removeItem(state, action)
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

export const filterProvider = (action: FilteredAction): Filter => ({
  archived: action.archived
})

export default collectionReducer(actions, itemsReducer, filterProvider, initialState)
