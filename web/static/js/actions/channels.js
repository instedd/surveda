// @flow
import * as api from '../api'
import * as guisso from './guisso'
import * as guissoApi from '../guisso'
import * as pigeon from '../pigeon'
import { config } from '../config'

export const RECEIVE = 'CHANNELS_RECEIVE'
export const FETCH = 'CHANNELS_FETCH'
export const NEXT_PAGE = 'CHANNELS_NEXT_PAGE'
export const PREVIOUS_PAGE = 'CHANNELS_PREVIOUS_PAGE'
export const SORT = 'CHANNELS_SORT'
export const CREATE = 'CHANNELS_CREATE'

export const fetchChannels = () => (dispatch: Function, getState: () => Store) => {
  const state = getState()

  // Don't fetch channels if they are already being fetched
  if (state.channels.fetching) {
    return
  }

  dispatch(startFetchingChannels())

  return api
    .fetchChannels()
    .then(response => dispatch(receiveChannels(response.entities.channels || {})))
    .then(() => getState().surveys.items)
}

export const startFetchingChannels = () => ({
  type: FETCH
})

export const receiveChannels = (channels: IndexedList<Channel>) => ({
  type: RECEIVE,
  channels
})

export const nextChannelsPage = () => ({
  type: NEXT_PAGE
})

export const previousChannelsPage = () => ({
  type: PREVIOUS_PAGE
})

export const sortChannelsBy = (property: string) => ({
  type: SORT,
  property
})

export const createChannel = (channel: Channel) => (dispatch: Function) => {
  api.createChannel(channel)
    .then(response => dispatch({
      type: CREATE,
      id: response.result,
      channel: response.entities.channels[response.result]
    }))
}

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
