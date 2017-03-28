import * as api from '../api'

export const RECEIVE = 'STEP_RECEIVE'

export const fetchStep = (dispatch) => {
  api.fetchStep().then(response => {
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
