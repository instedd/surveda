import * as actions from '../actions/authorizations'

const initialState = {
  fetching: false,
  items: null
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.FETCH_AUTHORIZATIONS: return fetchAuthorizations(state)
    case actions.RECEIVE_AUTHORIZATIONS: return receiveAuthorizations(state, action)
    case actions.DELETE_AUTHORIZATION: return deleteAuthorization(state, action)
    case actions.ADD_AUTHORIZATION: return addAuthorization(state, action)
    default: return state
  }
}

const fetchAuthorizations = (state) => ({
  ...state,
  fetching: true
})

const receiveAuthorizations = (state, action) => ({
  ...state,
  fetching: false,
  items: action.authorizations
})

const deleteAuthorization = (state, action) => {
  const index = state.items.indexOf(action.provider)

  if (index == -1) {
    return state
  }

  return {
    ...state,
    items: [
      ...state.items.slice(0, index),
      ...state.items.slice(index + 1)
    ]
  }
}

const addAuthorization = (state, action) => {
  if (state.items.includes(action.provider)) {
    return state
  }

  return {
    ...state,
    items: [
      ...state.items,
      action.provider
    ]
  }
}
