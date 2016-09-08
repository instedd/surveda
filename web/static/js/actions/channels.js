import * as api from '../api'

export const RECEIVE_CHANNELS = "RECEIVE_CHANNELS"

export const fetchChannels = () => dispatch => {
  api.fetchChannels()
    .then(channels => dispatch(receiveChannels(channels)))
}

export const receiveChannels = (response) => ({
  type: RECEIVE_CHANNELS,
  response
})
