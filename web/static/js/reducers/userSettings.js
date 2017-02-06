import * as actions from '../actions/userSettings'

const initialState = {
  fetching: false,
  settings: null
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.FETCH_SETTINGS: return fetchSettings(state, action)
    case actions.RECEIVE_SETTINGS: return receiveSettings(state, action)
    default: return state
  }
}

const receiveSettings = (state, action) => {
  const items = action.response.settings
  return {
    ...state,
    fetching: false,
    settings: items
  }
}

const fetchSettings = (state, action) => {
  return {
    ...state,
    settings: state.settings,
    fetching: true
  }
}
