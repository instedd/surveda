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

export const receiveChannels = (items: IndexedList<Channel>): ReceiveItemsAction => ({
  type: RECEIVE,
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
