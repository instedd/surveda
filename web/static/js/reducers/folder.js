// @flow
import * as actions from '../actions/folder'

export default (state = [], action) => {
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
    default:
      return state
  }
}
