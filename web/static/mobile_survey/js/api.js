// @flow
import 'isomorphic-fetch'

export const fetchStep = (id: any) => {
  return fetch(`/mobile_survey/get_step/${encodeURIComponent(id)}`, {
    credentials: 'same-origin'
  })
}

export const sendReply = (id: any, value: any) => {
  return fetch(`/mobile_survey/send_reply/${encodeURIComponent(id)}?value=${encodeURIComponent(value)}`, {
    method: 'POST',
    credentials: 'same-origin'
  })
}
