// @flow
import * as api from '../api'

export const SHARE = 'CHANNEL_SHARE'
export const FETCH = 'CHANNEL_FETCH'
export const RECEIVE = 'CHANNEL_RECEIVE'
export const SAVING = 'CHANNEL_SAVING'
export const SAVED = 'CHANNEL_SAVED'

export const createChannel = (projectId: number) => (dispatch: Function, getState: () => Store) =>
  api.createChannel(projectId).then(response => {
    const channel = response.result
    dispatch(fetch(projectId, channel.id))
    dispatch(receive(channel))
    return channel
  })

export const fetchChannel = (projectId: number, id: number) => (dispatch: Function, getState: () => Store): Channel => {
  dispatch(fetch(projectId, id))
  return api.fetchChannel(projectId, id)
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

export const fetchChannelIfNeeded = (projectId: number, id: number) => (dispatch: Function, getState: () => Store): Promise<?Channel> => {
  if (shouldFetch(getState().channel, projectId, id)) {
    return dispatch(fetchChannel(projectId, id))
  } else {
    return Promise.resolve(getState().channel.data)
  }
}

export const receive = (channel: Channel) => ({
  type: RECEIVE,
  data: channel
})

export const shouldFetch = (state: DataStore<Channel>, projectId: number, id: number) => {
  return !state.fetching || !(state.filter && (state.filter.projectId == projectId && state.filter.id == id))
}

export const share = (projectId: string) => ({
  type: SHARE,
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
