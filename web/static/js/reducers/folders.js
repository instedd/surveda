// @flow
import * as actions from '../actions/folders'

const initialState = {
  loading: false,
  error: null,
  loadingFetch: false,
  items: null
}

const deleteFolder = (state, action) => {
  const newState = {...state}
  delete newState.items[action.id]
  return {
    ...newState
  }
}

const renameFolder = (state, action) => {
  const newState = {...state}
  newState.items[action.id].name = action.name
  newState.items[action.id].error = null
  return {
    ...newState,
    error: null
  }
}

const createFolder = (state, action) => {
  const newState = {...state}
  const { folder } = action
  newState.items = newState.items || {}
  newState.items[folder.id] = folder
  newState.items[folder.id].error = null

  return {
    ...newState,
    error: null
  }
}

const includeError = (state, action) => {
  const newState = {...state}
  newState.items[action.id].error = action.error
  return newState
}

export default (state: any = initialState, action: any) => {
  switch (action.type) {
    case actions.CREATE_FOLDER:
      return {
        ...state,
        name: action.name
      }
    case actions.SAVING_FOLDER:
      return {
        ...state,
        loading: true
      }
    case actions.CREATED_FOLDER: return createFolder(state, action)
    case actions.DELETED_FOLDER: return deleteFolder(state, action)
    case actions.RENAMED_FOLDER: return renameFolder(state, action)
    case actions.NOT_SAVED_FOLDER:
      return {
        ...state,
        error: action.error
      }
    case actions.NOT_RENAMED_FOLDER: return includeError(state, action)
    case actions.FETCH_FOLDERS:
      return {
        ...state,
        loadingFetch: true
      }
    case actions.RECEIVE_FOLDERS:
      return {
        ...state,
        items: action.folders,
        loadingFetch: false
      }
    default:
      return state
  }
}
