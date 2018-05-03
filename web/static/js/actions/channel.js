// @flow
import * as api from '../api'

export const SHARE = 'CHANNEL_SHARE'
export const REMOVE_SHARED_PROJECT = 'CHANNEL_REMOVE_SHARED_PROJECT'
export const FETCH = 'CHANNEL_FETCH'
export const RECEIVE = 'CHANNEL_RECEIVE'
export const SAVING = 'CHANNEL_SAVING'
export const SAVED = 'CHANNEL_SAVED'

export const updateChannel = () => (dispatch: Function, getState: () => Store) => {
  dispatch(saving())
  api.updateChannel(getState().channel.data).then(response => {
    dispatch(saved(response.result))
  })
}

export const fetchChannel = (id: number) => (dispatch: Function, getState: () => Store): Channel => {
  dispatch(fetch(id))
  return api.fetchChannel(id)
    .then(response => {
      dispatch(receive(response.entities.channels[response.result]))
    })
    .then(() => {
      return getState().channel.data
    })
}

export const fetch = (id: number): FilteredAction => ({
  type: FETCH,
  id
})

export const fetchChannelIfNeeded = (id: number) => (dispatch: Function, getState: () => Store): Promise<?Channel> => {
  if (shouldFetch(getState().channel, id)) {
    return dispatch(fetchChannel(id))
  } else {
    return Promise.resolve(getState().channel.data)
  }
}

export const receive = (channel: Channel) => ({
  type: RECEIVE,
  data: channel
})

export const shouldFetch = (state: DataStore<Channel>, id: number) => {
  return !state.fetching || !(state.filter && state.filter.id == id)
}

export const shareWithProject = (projectId: number) => ({
  type: SHARE,
  projectId
})

export const removeSharedProject = (projectId: number) => ({
  type: REMOVE_SHARED_PROJECT,
  projectId
})

export const saving = () => ({
  type: SAVING
})

export const saved = (channel: Channel) => ({
  type: SAVED,
  data: channel
})

export const save = () => (dispatch: Function, getState: () => Store) => {
  const channel = getState().channel.data
  if (!channel) return
  dispatch(saving())
  return api.updateChannel(channel.projectId, channel)
    .then(response =>
       dispatch(saved(response.entities.channels[response.result]))
    )
}
