// @flow
import 'isomorphic-fetch'

export const fetchStep = (id: any, token: string) => {
  return fetch(`/mobile_survey/get_step/${encodeURIComponent(id)}?token=${encodeURIComponent(token)}`, {
    credentials: 'same-origin'
  })
}

export const sendReply = (respondentId: any, token: string, stepId: any, value: any) => {
  return fetch(`/mobile_survey/send_reply/${encodeURIComponent(respondentId)}?value=${encodeURIComponent(value)}&step_id=${encodeURIComponent(stepId)}&token=${encodeURIComponent(token)}`, {
    method: 'POST',
    credentials: 'same-origin'
  })
}
