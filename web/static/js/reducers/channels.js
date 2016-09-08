import * as actions from '../actions/channels'

export default (state = {}, action) => {
  switch (action.type) {
    case actions.RECEIVE_CHANNELS:
      return action.response.entities.channels || {};
    case actions.CREATE_CHANNEL:
      return {
        ...state,
        [action.id]: {
          ...action.channel
        }
      }
    default:
      return state;
  }
}
