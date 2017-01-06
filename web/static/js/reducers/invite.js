import * as actions from '../actions/invites'

const initialState = {
  fetching: false,
  data: null
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.FETCH_INVITE: return fetchInvite(state, action)
    default: return state
  }
}

const fetchInvite = (state, action) => {
  return {
    ...state,
    data: state.data
  }
}
