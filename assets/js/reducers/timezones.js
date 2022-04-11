import * as actions from "../actions/timezones"

const initialState = {
  fetching: false,
  items: null,
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.RECEIVE_TIMEZONES: {
      return {
        ...state,
        fetching: false,
        items: action.timezones,
      }
    }
    case actions.FETCH_TIMEZONES: {
      return {
        ...state,
        fetching: true,
      }
    }
    default:
      return state
  }
}
