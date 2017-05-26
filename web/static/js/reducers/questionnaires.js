// @flow
import * as actions from '../actions/questionnaires'
import collectionReducer, { projectFilterProvider } from './collection'

const itemsReducer = (state: IndexedList<Questionnaire>, action): IndexedList<Questionnaire> => {
  switch (action.type) {
    case actions.DELETED: return deleteItem(state, action)
    default: return state
  }
}

const deleteItem = (state: IndexedList<Questionnaire>, action: any) => {
  const items = {...state}
  delete items[action.id]
  return items
}

export default collectionReducer(actions, itemsReducer, projectFilterProvider)
