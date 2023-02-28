import * as actions from "../actions/project"
import { camelizeKeys } from "humps"

const initialState = {
  fetching: false,
  projectId: null,
  data: null,
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.FETCH_PROJECT:
      return fetchProject(state, action)
    case actions.RECEIVE_PROJECT:
      return receiveProject(state, action)
    case actions.CREATE_PROJECT:
      return createOrUpdateProject(state, action)
    case actions.UPDATE_PROJECT:
      return createOrUpdateProject(state, action)
    case actions.SAVING_PROJECT:
      return savingProject(state)
    case actions.NOT_SAVED_PROJECT:
      return notSavedProject(state, action)
    case actions.CLEAR_PROJECT:
      return clearProject(state, action)
    default:
      return state
  }
}

const fetchProject = (state, action) => {
  // Keep old data while reloading the same project
  const newData = state.projectId == action.projectId ? state.data : null
  return {
    ...state,
    fetching: true,
    projectId: action.projectId,
    data: newData,
  }
}

const receiveProject = (state, action) => {
  // Ignore if receiving a project that's not the last requested one
  if (state.projectId != action.project.id) {
    return state
  }

  return {
    ...state,
    fetching: false,
    data: action.project,
  }
}

const savingProject = (state) => ({
  ...state,
  saving: true,
})

const createOrUpdateProject = (state, action) => ({
  ...state,
  fetching: false,
  saving: false,
  projectId: action.project.id,
  data: action.project,
  errors: null,
})

const notSavedProject = (state, action) => ({
  ...state,
  saving: false,
  errors: camelizeKeys(action.errors)
})

const clearProject = (state, action) => ({
  ...state,
  fetching: false,
  saving: false,
  projectId: null,
  data: null,
  errors: null,
})

export const isProjectReadOnly = (state) =>
  state.project && state.project.data ? state.project.data.readOnly : true
