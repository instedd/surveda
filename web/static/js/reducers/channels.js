import * as actions from '../actions/channels'

export default (state = {}, action) => {
  switch (action.type) {
    case actions.RECEIVE_CHANNELS:
      if (action.response && action.response.entities) {
        return action.response.entities.channels || {}
      }
      return state
    case actions.CREATE_CHANNEL:
      return {
        ...state,
        [action.id]: {
          ...action.channel
        }
      }
    default:
      return state
  }
}
