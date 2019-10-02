// @flow
import * as actions from '../actions/folder'

const initialState = {
  loading: false,
  error: null,
  loadingFetch: false
}

const deleteFolder = (state, action) => {
  const newState = {...state}
  delete newState.folders[action.id]
  return {
    ...newState
  }
}

const renameFolder = (state, action) => {
  const newState = {...state}
  newState.folders[action.id].name = action.name
  newState.folders[action.id].error = null
  return {
    ...newState,
    error: null
  }
}

const createFolder = (state, action) => {
  const newState = {...state}
  const { folder } = action
  newState.folders = newState.folders || {}
  newState.folders[folder.id] = folder
  newState.folders[folder.id].error = null
  return {
    ...newState,
    error: null
  }
}

const includeError = (state, action) => {
  const newState = {...state}
  newState.folders[action.id].error = action.error
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
    case actions.FETCHING_FOLDERS:
      return {
        ...state,
        loadingFetch: true
      }
    case actions.FETCH_FOLDERS:
      return {
        ...state,
        folders: []
      }
    case actions.FETCHED_FOLDERS:
      return {
        ...state,
        folders: action.folders,
        loadingFetch: false
      }
    case actions.FETCHING_FOLDER:
      return {
        ...state,
        loadingFetch: true
      }
    case actions.FETCH_FOLDER:
      return {
        ...state,
        folder: null
      }
    default:
      return state
  }
}
