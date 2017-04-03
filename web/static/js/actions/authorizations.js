import * as api from '../api'
import * as guissoApi from '../guisso'
import * as channelActions from './channels'
import { config } from '../config'
import some from 'lodash/some'

export const FETCH_AUTHORIZATIONS = 'FETCH_AUTHORIZATIONS'
export const RECEIVE_AUTHORIZATIONS = 'RECEIVE_AUTHORIZATIONS'
export const DELETE_AUTHORIZATION = 'DELETE_AUTHORIZATION'
export const ADD_AUTHORIZATION = 'ADD_AUTHORIZATION'
export const BEGIN_SYNCHRONIZATION = 'BEGIN_SYNCHRONIZATION'
export const END_SYNCHRONIZATION = 'END_SYNCHRONIZATION'

export const fetchAuthorizations = () => (dispatch, getState) => {
  const state = getState()

  if (state.authorizations.fetching) {
    return
  }

  dispatch(startFetchingAuthorizations())
  return api.fetchAuthorizations()
    .then(response => dispatch(receiveAuthorizations(response.data)))
}

export const startFetchingAuthorizations = () => ({
  type: FETCH_AUTHORIZATIONS
})

export const receiveAuthorizations = (authorizations) => ({
  type: RECEIVE_AUTHORIZATIONS,
  authorizations
})

export const deleteAuthorization = (provider, baseUrl) => ({
  type: DELETE_AUTHORIZATION,
  provider,
  baseUrl
})

export const addAuthorization = (provider, baseUrl) => ({
  type: ADD_AUTHORIZATION,
  provider,
  baseUrl
})

export const toggleAuthorization = (provider, index) => (dispatch, getState) => {
  const state = getState().authorizations

  if (state.fetching || state.items == null) {
    return
  }

  const baseUrl = config[provider][index].baseUrl
  const currentValue = hasInAuthorizations(state, provider, index)

  if (currentValue) {
    // Turn off
    dispatch(deleteAuthorization(provider, baseUrl))
    api.deleteAuthorization(provider, baseUrl)
      .then(() => { dispatch(channelActions.fetchChannels()) })
      .catch((e) => {
        dispatch(addAuthorization(provider, baseUrl))
      })
  } else {
    // Turn on
    dispatch(addAuthorization(provider, baseUrl))
    const guissoSession = guissoApi.newSession(config[provider][index].guisso)
    return guissoSession.authorize('code', provider, baseUrl)
      .then(() => guissoSession.close())
      .then(() => { dispatch(channelActions.fetchChannels()) })
      .catch((err) => {
        guissoSession.close()
        dispatch(deleteAuthorization(provider, baseUrl))
        if (err) {
          throw err
        }
      })
  }
}

export const removeAuthorization = (provider, index) => (dispatch, getState) => {
  const state = getState().authorizations

  if (state.fetching || state.items == null) {
    return
  }

  const baseUrl = config[provider][index].baseUrl

  dispatch(deleteAuthorization(provider, baseUrl))
  api.deleteAuthorization(provider, baseUrl, true)
    .catch((e) => {
      dispatch(addAuthorization(provider, baseUrl))
    })
}

export const beginSynchronization = () => ({
  type: BEGIN_SYNCHRONIZATION
})

export const endSynchronization = () => ({
  type: END_SYNCHRONIZATION
})

export const synchronizeChannels = () => (dispatch, getState) => {
  dispatch(beginSynchronization())
  api.synchronizeChannels()
    .then(() => { dispatch(endSynchronization()) })
    .then(() => { dispatch(channelActions.fetchChannels()) })
}

export const hasInAuthorizations = (authorizations, provider, index) => {
  const baseUrl = config[provider][index].baseUrl
  return !!(authorizations.items && some(authorizations.items, item => item.provider == provider && item.baseUrl == baseUrl))
}
