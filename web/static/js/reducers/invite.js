import * as actions from '../actions/invites'

const initialState = {
  fetching: false,
  data: null
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.RECEIVE_INVITE: return receiveInvite(state, action)
    default: return state
  }
}

const receiveInvite = (state, action) => {
  return {
    ...state,
    data: action.data
  }
}
