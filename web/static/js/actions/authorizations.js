import * as api from '../api'
import * as guissoApi from '../guisso'
import { config } from '../config'

export const FETCH_AUTHORIZATIONS = 'FETCH_AUTHORIZATIONS'
export const RECEIVE_AUTHORIZATIONS = 'RECEIVE_AUTHORIZATIONS'
export const DELETE_AUTHORIZATION = 'DELETE_AUTHORIZATION'
export const ADD_AUTHORIZATION = 'ADD_AUTHORIZATION'

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

export const deleteAuthorization = (provider) => ({
  type: DELETE_AUTHORIZATION,
  provider
})

export const addAuthorization = (provider) => ({
  type: ADD_AUTHORIZATION,
  provider
})

export const toggleAuthorization = (provider) => (dispatch, getState) => {
  const state = getState().authorizations

  if (state.fetching || state.items == null) {
    return
  }

  const currentValue = state.items.includes(provider)

  if (currentValue) {
    // Turn off
    dispatch(deleteAuthorization(provider))
    api.deleteAuthorization(provider)
      .catch((e) => {
        dispatch(addAuthorization(provider))
      })
  } else {
    // Turn on
    dispatch(addAuthorization(provider))
    const guissoSession = guissoApi.newSession(config[provider].guisso)
    return guissoSession.authorize('code', provider)
      .then(() => guissoSession.close())
      .catch(() => {
        dispatch(deleteAuthorization(provider))
      })
  }
}
