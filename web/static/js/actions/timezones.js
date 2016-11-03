export const RECEIVE_TIMEZONES = 'RECEIVE_TIMEZONES'

export const receiveTimezones = (data) => ({
  type: RECEIVE_TIMEZONES,
  timezones: data.timezones
})
