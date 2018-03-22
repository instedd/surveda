import * as actions from '../actions/activities'
import collectionReducer, { projectFilterProvider } from './collection'

const itemsReducer = (state: IndexedList<Project>, action): IndexedList<Project> => {
  return state
}

const initialState = {
  fetching: false,
  items: null,
  filter: null,
  order: null,
  sortBy: 'insertedAt',
  sortAsc: false,
  page: {
    index: 0,
    size: 15
  }
}

export default collectionReducer(actions, itemsReducer, projectFilterProvider, initialState)
