import * as api from '../api'
export const RECEIVE_TIMEZONES = 'RECEIVE_TIMEZONES'
export const FETCH_TIMEZONES = 'FETCH_TIMEZONES'

export const fetchTimezones = () => (dispatch, getState) => {
  const state = getState()
  if (state.timezones.fetching || state.timezones.items) {
    return
  }
  dispatch(startFetchingTimezones())

  return api
    .fetchTimezones()
    .then(response => dispatch(receiveTimezones(response)))
    .then(() => getState().surveys.items)
}

export const receiveTimezones = (data) => ({
  type: RECEIVE_TIMEZONES,
  timezones: data.timezones
})

export const startFetchingTimezones = () => ({
  type: FETCH_TIMEZONES
})
