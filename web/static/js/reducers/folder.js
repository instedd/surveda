// @flow
import * as actions from '../actions/folder'

export default (state: any = {}, action: any) => {
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
    case actions.SAVED_FOLDER:
      return {
        ...state,
        errors: {},
        loading: false
      }

    case actions.NOT_SAVED_FOLDER:
      return {
        ...state,
        errors: action.errors,
        loading: false
      }
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
    case actions.FETCHED_FOLDER:
      return {
        ...state,
        folder: action.folder,
        loadingFetch: false
      }
    default:
      return state
  }
}
