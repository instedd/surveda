// @flow
import 'isomorphic-fetch'

export const fetchStep = (id: any) => {
  return fetch(`/mobile_survey/get_step/${encodeURIComponent(id)}`, {
    credentials: 'same-origin'
  })
}

export const sendReply = (respondentId: any, stepId: any, value: any) => {
  return fetch(`/mobile_survey/send_reply/${encodeURIComponent(respondentId)}?value=${encodeURIComponent(value)}&step_id=${encodeURIComponent(stepId)}`, {
    method: 'POST',
    credentials: 'same-origin'
  })
}
