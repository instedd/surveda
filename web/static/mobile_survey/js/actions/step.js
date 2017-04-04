import * as api from '../api'

export const RECEIVE = 'STEP_RECEIVE'

export const fetchStep = (dispatch) => {
  let match = window.location.search.match('mode\=(\\d)')
  let mode = match ? match[1] : 0

  api.fetchStep(mode).then(response => {
    response.json().then(json => {
      dispatch(receiveStep(json.step))
    })
  })
}

export const sendReply = (id, value) => {
  api.sendReply(id, value)
}

const receiveStep = step => ({
  type: RECEIVE,
  step
})
