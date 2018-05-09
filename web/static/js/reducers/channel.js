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
    case actions.CREATE_PATTERN: return createPattern(state)
    case actions.SET_INPUT_PATTERN: return setInputPattern(state, action)
    case actions.SET_OUTPUT_PATTERN: return setOutputPattern(state, action)
    case actions.REMOVE_PATTERN: return removePattern(state, action)
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

const createPattern = (state) => {
  return {
    ...state,
    patterns: [...state.patterns, {'input': '', 'output': ''}]
  }
}

const setInputPattern = (state, action) => {
  const previousPattern = state.patterns[action.index]
  const patterns = [
    ...state.patterns.slice(0, action.index),
    {'input': action.value, 'output': previousPattern.output},
    ...state.patterns.slice(action.index + 1)
  ]
  return {
    ...state,
    patterns: patterns
  }
}

const setOutputPattern = (state, action) => {
  const previousPattern = state.patterns[action.index]
  const patterns = [
    ...state.patterns.slice(0, action.index),
    {'input': previousPattern.input, 'output': action.value},
    ...state.patterns.slice(action.index + 1)
  ]
  return {
    ...state,
    patterns: patterns
  }
}

const removePattern = (state, action) => {
  const patterns = [...state.patterns]
  const newPatterns = [
    ...patterns.slice(0, action.index),
    ...patterns.slice(action.index + 1)
  ]
  return {...state, patterns: newPatterns}
}
