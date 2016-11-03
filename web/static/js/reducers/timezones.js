import * as actions from '../actions/timezones'

export default (state = {}, action) => {
  switch (action.type) {
    case actions.RECEIVE_TIMEZONES: {
      return {
        ...state,
        timezones: action.timezones
      }
    }
    default: return state
  }
}
