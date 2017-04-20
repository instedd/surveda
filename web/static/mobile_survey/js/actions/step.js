// @flow
import * as api from '../api'

export const RECEIVE = 'STEP_RECEIVE'

export const fetchStep = (dispatch: (action: any) => any, respondentId: any) => {
  return api.fetchStep(respondentId).then((response: any) => {
    response.json().then(json => {
      dispatch(receiveStep(json.step, json.progress))
    })
  })
}

export const sendReply = (dispatch: (action: any) => any, id: any, value: any) => {
  return api.sendReply(id, value).then((response: any) => {
    response.json().then(json => {
      dispatch(receiveStep(json.step, json.progress))
    })
  })
}

const receiveStep = (step, progress) => ({
  type: RECEIVE,
  step,
  progress
})
