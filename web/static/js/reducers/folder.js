// @flow
import * as actions from '../actions/folder'

const initialState = {
  loading: false
}

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
        loading: false
      }
    default:
      return state
  }
}
