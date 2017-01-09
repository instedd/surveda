// @flow
import * as api from '../api'
import * as guisso from './guisso'
import * as guissoApi from '../guisso'
import * as pigeon from '../pigeon'
import { config } from '../config'

export const RECEIVE_CHANNELS = 'RECEIVE_CHANNELS'
export const CREATE_CHANNEL = 'CREATE_CHANNEL'

export const fetchChannels = () => (dispatch: Function) => {
  api.fetchChannels()
    .then(channels => dispatch(receiveChannels(channels)))
}

export const createChannel = (channel: Channel) => (dispatch: Function) => {
  api.createChannel(channel)
    .then(response => dispatch({
      type: CREATE_CHANNEL,
      id: response.result,
      channel: response.entities.channels[response.result]
    }))
}

export const receiveChannels = (response: Channel[]) => ({
  type: RECEIVE_CHANNELS,
  response
})

export const createNuntiumChannel = (() => {
  let references = {guissoSession: null}
  return () => (dispatch: Function) => {
    if (references.guissoSession && references.guissoSession.isPopupOpen()) {
      return Promise.resolve()
    }
    return Promise.all([
      authorizeWithGuisso(dispatch, 'nuntium', config.nuntium, references),
      pigeon.loadPigeonScript(config.nuntium.baseUrl)
    ])
      .then(([token, _]) => pigeon.addChannel(token.access_token))
      .then(nuntiumChannel => {
        if (nuntiumChannel == null) {
          return Promise.reject('User cancelled')
        }
        dispatch(createChannel({
          name: nuntiumChannel.name,
          type: 'sms',
          provider: 'nuntium',
          settings: {
            nuntiumChannel: nuntiumChannel.name
          }
        }))
      }).catch((_) => _)
  }
})()

const authorizeWithGuisso = (dispatch, app, appConfig, references) => {
  const guissoSession = guissoApi.newSession(appConfig.guisso)
  references.guissoSession = guissoSession
  return guissoSession.authorize('code', app)
    .then(() => dispatch(guisso.obtainToken(guissoSession)))
    .then((token) => {
      guissoSession.close()
      return token
    })
}
