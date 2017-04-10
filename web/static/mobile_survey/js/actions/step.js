// @flow
import * as api from '../api'

export const RECEIVE = 'STEP_RECEIVE'

export const fetchStep = (dispatch: (action: any) => any, respondentId: any) => {
  api.fetchStep(respondentId).then((response: any) => {
    response.json().then(json => {
      dispatch(receiveStep(json.step))
    })
  })
}

export const sendReply = (dispatch: (action: any) => any, id: any, value: any) => {
  api.sendReply(id, value).then((response: any) => {
    response.json().then(json => {
      dispatch(receiveStep(json.step))
    })
  })
}

const receiveStep = step => ({
  type: RECEIVE,
  step
})
