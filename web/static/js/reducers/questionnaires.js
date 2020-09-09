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

// TODO: This filter breaks the tests
const filterProvider = (action: FilteredAction): Filter => ({
  ...projectFilterProvider(action),
  archived: action.archived
})

export default collectionReducer(actions, itemsReducer, filterProvider)
