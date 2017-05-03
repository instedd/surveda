// @flow
import * as api from '../api'

export const RECEIVE = 'STEP_RECEIVE'

export const fetchStep = (dispatch: (action: any) => any, respondentId: any, token: string) => {
  return api.fetchStep(respondentId, token).then((response: any) => {
    response.json().then(json => {
      dispatch(receiveStep(json))
    })
  })
}

export const sendReply = (dispatch: (action: any) => any, respondentId: any, token: string, stepId: any, value: any) => {
  return api.sendReply(respondentId, token, stepId, value).then((response: any) => {
    response.json().then(json => {
      dispatch(receiveStep(json))
    })
  })
}

const receiveStep = (json) => ({
  type: RECEIVE,
  step: json.step,
  progress: json.progress,
  errorMessage: json.errorMessage,
  title: json.title
})
