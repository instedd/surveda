// @flow
import * as actions from '../actions/channel'
import fetchReducer from './fetch'
import toInteger from 'lodash/toInteger'

export const dataReducer = (state: Channel, action: any): Channel => {
  switch (action.type) {
    case actions.SHARE: return share(state, action)
    default: return state
  }
}

const filterProvider = (action: FilteredAction) => ({
  id: action.id == null ? null : toInteger(action.id)
})

export default fetchReducer(actions, dataReducer, filterProvider)

const share = (state, action) => {
  return {
    ...state,
    projects: [
      ...state.projects,
      action.projectId
    ]
  }
}
