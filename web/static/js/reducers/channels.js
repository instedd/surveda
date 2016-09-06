import * as actions from '../actions/channels'

export default (state = {}, action) => {
  switch (action.type) {
    case actions.RECEIVE_CHANNELS:
      return action.response.entities.channels || {};
    default:
      return state;
  }
}
