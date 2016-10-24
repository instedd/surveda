import * as actions from '../actions/channels'

export default (state = {}, action) => {
  switch (action.type) {
    case actions.RECEIVE_CHANNELS: return receiveChannels(state, action)
    case actions.CREATE_CHANNEL: return createChannel(state, action)
    default: return state
  }
}

const receiveChannels = (state, action) => {
  if (action.response && action.response.entities) {
    return action.response.entities.channels || {}
  }
  return state
}

const createChannel = (state, action) => ({
  ...state,
  [action.id]: {
    ...action.channel
  }
})

