// @flow
import * as actions from '../actions/channels'
import collectionReducer, { projectFilterProvider } from './collection'

const itemsReducer = (state: IndexedList<Channel>, action: any): IndexedList<Channel> => {
  switch (action.type) {
    case actions.CREATE: return create(state, action)
    default: return state
  }
}

export default collectionReducer(actions, itemsReducer, projectFilterProvider)

const create = (state, action) => {
  return {
    ...state,
    items: {
      ...state.items,
      [action.id]: {
        ...action.channel
      }
    }
  }
}
