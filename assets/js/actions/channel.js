// @flow
import * as api from "../api"

export const SHARE = "CHANNEL_SHARE"
export const REMOVE_SHARED_PROJECT = "CHANNEL_REMOVE_SHARED_PROJECT"
export const CREATE_PATTERN = "CHANNEL_CREATE_PATTERN"
export const SET_INPUT_PATTERN = "CHANNEL_SET_INPUT_PATTERN"
export const SET_OUTPUT_PATTERN = "CHANNEL_SET_OUTPUT_PATTERN"
export const REMOVE_PATTERN = "CHANNEL_REMOVE_PATTERN"
export const SET_CAPACITY = "CHANNEL_SET_CAPACITY"
export const FETCH = "CHANNEL_FETCH"
export const RECEIVE = "CHANNEL_RECEIVE"
export const SAVING = "CHANNEL_SAVING"
export const SAVED = "CHANNEL_SAVED"

export const updateChannel = () => (dispatch: Function, getState: () => Store) => {
  dispatch(saving())
  api.updateChannel(getState().channel.data).then((response) => {
    dispatch(saved(response.result))
  })
}

export const fetchChannel =
  (id: number) =>
  (dispatch: Function, getState: () => Store): Channel => {
    dispatch(fetch(id))
    return api
      .fetchChannel(id)
      .then((response) => {
        dispatch(receive(response.entities.channels[response.result]))
      })
      .then(() => {
        return getState().channel.data
      })
  }

export const fetch = (id: number): FilteredAction => ({
  type: FETCH,
  id,
})

export const fetchChannelIfNeeded =
  (id: number) =>
  (dispatch: Function, getState: () => Store): Promise<?Channel> => {
    if (shouldFetch(getState().channel, id)) {
      return dispatch(fetchChannel(id))
    } else {
      return Promise.resolve(getState().channel.data)
    }
  }

export const receive = (channel: Channel) => ({
  type: RECEIVE,
  data: channel,
})

export const shouldFetch = (state: DataStore<Channel>, id: number) => {
  return !state.fetching || !(state.filter && state.filter.id == id)
}

export const shareWithProject = (projectId: number) => ({
  type: SHARE,
  projectId,
})

export const removeSharedProject = (projectId: number) => ({
  type: REMOVE_SHARED_PROJECT,
  projectId,
})

export const createPattern = {
  type: CREATE_PATTERN,
}

export const setInputPattern = (index: number, value: string) => ({
  type: SET_INPUT_PATTERN,
  index,
  value,
})

export const setOutputPattern = (index: number, value: string) => ({
  type: SET_OUTPUT_PATTERN,
  index,
  value,
})

export const removePattern = (index: number) => ({
  type: REMOVE_PATTERN,
  index,
})

export const setCapacity = (value: number) => ({
  type: SET_CAPACITY,
  value: value,
})

export const saving = () => ({
  type: SAVING,
})

export const saved = (channel: Channel) => ({
  type: SAVED,
  data: channel,
})

export const save = () => (dispatch: Function, getState: () => Store) => {
  const channel = getState().channel.data
  if (!channel) return
  dispatch(saving())
  return api
    .updateChannel(channel.projectId, channel)
    .then((response) => dispatch(saved(response.entities.channels[response.result])))
}

export const addPattern = () => (dispatch: Function, getState: () => Store) => {
  dispatch(createPattern)
}

export const changeInputPattern =
  (index: number, value: string) => (dispatch: Function, getState: () => Store) => {
    dispatch(setInputPattern(index, value))
  }

export const changeOutputPattern =
  (index: number, value: string) => (dispatch: Function, getState: () => Store) => {
    dispatch(setOutputPattern(index, value))
  }

export const deletePattern = (index: number) => (dispatch: Function, getState: () => Store) => {
  dispatch(removePattern(index))
}
