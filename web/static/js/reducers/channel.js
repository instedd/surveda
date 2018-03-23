// @flow
import * as actions from '../actions/channel'
import fetchReducer from './fetch'
import toInteger from 'lodash/toInteger'
import findIndex from 'lodash/findIndex'
import isEqual from 'lodash/isEqual'

export const dataReducer = (state: Channel, action: any): Channel => {
  switch (action.type) {
    case actions.SHARE: return share(state, action)
    case actions.REMOVE_SHARED_PROJECT: return removeSharedProject(state, action)
    default: return state
  }
}

const filterProvider = (action: FilteredAction) => ({
  id: action.id == null ? null : toInteger(action.id)
})

export default fetchReducer(actions, dataReducer, filterProvider)

const share = (state, action) => {
  console.log('state: ', state)
  console.log('action: ', action)
  return {
    ...state,
    projects: [
      ...state.projects,
      action.projectId
    ]
  }
}

const removeSharedProject = (state, action) => {
  const projectIndex = findIndex(state.projects, (projectId) =>
    isEqual(projectId, action.projectId)
  )
  return {
    ...state,
    projects: [
      ...state.projects.slice(0, projectIndex),
      ...state.projects.slice(projectIndex + 1)
    ]
  }
}
