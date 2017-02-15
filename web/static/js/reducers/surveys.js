// @flow
import * as actions from '../actions/surveys'
import collectionReducer, { projectFilterProvider } from './collection'

const itemsReducer = (state: IndexedList<Survey>, action): IndexedList<Survey> => {
  switch (action.type) {
    case actions.DELETED: return deleteItem(state, action)
    default: return state
  }
}

const deleteItem = (state: IndexedList<Survey>, action: any) => {
  const items = {...state}
  delete items[action.id]
  return items
}

export default collectionReducer(actions, itemsReducer, projectFilterProvider)
