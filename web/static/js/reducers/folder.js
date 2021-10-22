// @flow
import * as actions from '../actions/folder'

const initialState = {
  fetching: false,
  error: null
}

export default (state: any = initialState, action: any) => {
  switch (action.type) {
    case actions.FETCH:
      return {
        ...state,
        fetching: true
      }
    case actions.RECEIVE:
      return {
        ...state,
        data: action.data,
        fetching: false
      }
    default:
      return state
  }
}
