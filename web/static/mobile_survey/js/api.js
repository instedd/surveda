import 'isomorphic-fetch'

export const fetchStep = () => {
  return fetch(`/mobile_survey/get_step`, { credentials: 'same-origin' })
}
