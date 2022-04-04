import * as actions from "../actions/authorizations"
import findIndex from "lodash/findIndex"

const initialState = {
  fetching: false,
  items: null,
  synchronizing: false,
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.FETCH_AUTHORIZATIONS:
      return fetchAuthorizations(state)
    case actions.RECEIVE_AUTHORIZATIONS:
      return receiveAuthorizations(state, action)
    case actions.DELETE_AUTHORIZATION:
      return deleteAuthorization(state, action)
    case actions.ADD_AUTHORIZATION:
      return addAuthorization(state, action)
    case actions.BEGIN_SYNCHRONIZATION:
      return beginSynchronization(state)
    case actions.END_SYNCHRONIZATION:
      return endSynchronization(state)
    default:
      return state
  }
}

const fetchAuthorizations = (state) => ({
  ...state,
  fetching: true,
})

const receiveAuthorizations = (state, action) => ({
  ...state,
  fetching: false,
  items: action.authorizations,
})

const deleteAuthorization = (state, action) => {
  const index = findIndex(
    state.items,
    (item) => item.provider == action.provider && item.baseUrl == action.baseUrl
  )

  if (index == -1) {
    return state
  }

  return {
    ...state,
    items: [...state.items.slice(0, index), ...state.items.slice(index + 1)],
  }
}

const addAuthorization = (state, action) => {
  const index = findIndex(
    state.items,
    (item) => item.provider == action.provider && item.baseUrl == action.baseUrl
  )
  if (index != -1) {
    return state
  }

  return {
    ...state,
    items: [
      ...state.items,
      {
        provider: action.provider,
        baseUrl: action.baseUrl,
      },
    ],
  }
}

const beginSynchronization = (state) => ({
  ...state,
  synchronizing: true,
})

const endSynchronization = (state) => ({
  ...state,
  synchronizing: false,
})
