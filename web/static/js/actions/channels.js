// @flow
import * as api from '../api'

export const RECEIVE = 'CHANNELS_RECEIVE'
export const FETCH = 'CHANNELS_FETCH'
export const NEXT_PAGE = 'CHANNELS_NEXT_PAGE'
export const PREVIOUS_PAGE = 'CHANNELS_PREVIOUS_PAGE'
export const SORT = 'CHANNELS_SORT'
export const CREATE = 'CHANNELS_CREATE'

export const fetchChannels = () => (dispatch: Function, getState: () => Store) => {
  const state = getState()

  // Don't fetch channels if they are already being fetched
  if (state.channels.fetching && state.channels.filter && !state.channels.filter.projectId) {
    return Promise.resolve(getState().channels.items)
  }

  dispatch(fetch())

  return api
    .fetchChannels()
    .then(response => dispatch(receiveChannels(response.entities.channels || {})))
    .then(() => getState().channels.items)
}

export const fetchProjectChannels = (projectId: number) => (dispatch: Function, getState: () => Store) => {
  const state = getState()

  // Don't fetch channels if they are already being fetched
  if (state.channels.fetching && state.channels.filter && state.channels.filter.projectId == projectId) {
    return Promise.resolve(getState().channels.items)
  }

  dispatch(fetch(projectId))

  return api
    .fetchProjectChannels(projectId)
    .then(response => dispatch(receiveChannels(response.entities.channels || {}, projectId)))
    .then(() => getState().channels.items)
}

export const fetch = (projectId: number | void) => ({
  type: FETCH,
  projectId
})

export const receiveChannels = (items: IndexedList<Channel>, projectId: number | void): ReceiveItemsAction => ({
  type: RECEIVE,
  projectId,
  items
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

export const createChannel = (providerType: string, baseUrl: string, channel: Object) =>
  (dispatch: Function) => {
    return api
      .createChannel(providerType, baseUrl, channel)
      .then(() => dispatch(fetchChannels()))
  }
