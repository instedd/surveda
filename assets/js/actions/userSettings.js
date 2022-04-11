import * as api from "../api"

export const RECEIVE_SETTINGS = "RECEIVE_SETTINGS"
export const FETCH_SETTINGS = "FETCH_SETTINGS"

export const fetchSettings = () => (dispatch) => {
  dispatch(startFetchingSettings())
  return api.fetchSettings().then((response) => {
    dispatch(receiveSettings(response))
  })
}

export const hideOnboarding = () => (dispatch) => {
  api.updateSettings({ settings: { onboarding: { questionnaire: true } } }).then((response) => {
    dispatch(receiveSettings(response.result))
  })
}

export const changeLanguage = (language) => (dispatch) => {
  return api.updateSettings({ settings: { language: language } }).then((response) => {
    dispatch(receiveSettings(response.result))
  })
}

export const receiveSettings = (response) => {
  return {
    type: RECEIVE_SETTINGS,
    response,
  }
}

export const startFetchingSettings = () => ({
  type: FETCH_SETTINGS,
})
