// @flow
import * as api from '../api'

export const RECEIVE = 'STEP_RECEIVE'

export const fetchStep = (dispatch: (action: any) => any, respondentId: any, token: string) => {
  return api.fetchStep(respondentId, token).then((response: any) => {
    response.json().then(json => {
      dispatch(receiveStep(json.step, json.progress, json.error_message))
    })
  })
}

export const sendReply = (dispatch: (action: any) => any, respondentId: any, token: string, stepId: any, value: any) => {
  return api.sendReply(respondentId, token, stepId, value).then((response: any) => {
    response.json().then(json => {
      dispatch(receiveStep(json.step, json.progress, json.error_message))
    })
  })
}

const receiveStep = (step, progress, errorMessage) => ({
  type: RECEIVE,
  step,
  progress,
  errorMessage
})
