import * as api from '../api'
import * as guisso from './guisso'
import * as pigeon from '../pigeon'
import { config } from '../config'

export const RECEIVE_CHANNELS = "RECEIVE_CHANNELS"
export const CREATE_CHANNEL = "CREATE_CHANNEL"

export const fetchChannels = () => dispatch => {
  api.fetchChannels()
    .then(channels => dispatch(receiveChannels(channels)))
}

export const createChannel = channel => dispatch => {
  api.createChannel(channel)
    .then(response => dispatch({
      type: CREATE_CHANNEL,
      id: response.result,
      channel: response.entities.channels[response.result]
    }))
}

export const receiveChannels = (response) => ({
  type: RECEIVE_CHANNELS,
  response
})

export const createNuntiumChannel = () => dispatch => {
  return Promise.all([
    dispatch(guisso.obtainToken(config.nuntium.guisso)),
    pigeon.loadPigeonScript(config.nuntium.baseUrl)
  ]).then(([token, _]) =>
    pigeon.addChannel(token.access_token)
  ).then(nuntiumChannel => {
    dispatch(createChannel({
      name: nuntiumChannel.name,
      type: 'sms',
      provider: 'nuntium',
      settings: {
        nuntiumChannel: nuntiumChannel.name
      }
    }))
  })
}
