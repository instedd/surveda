// @flow
import * as actions from '../actions/projects'
import collectionReducer, { defaultFilterProvider } from './collection'

const itemsReducer = (state: IndexedList<Project>, _): IndexedList<Project> => state

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
