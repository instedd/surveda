// @flow
import * as actions from '../actions/channels'
import { itemsOrder, sortItems, nextPage, previousPage } from '../dataTable'

const initialState = {
  fetching: false,
  projectId: null,
  items: null,
  order: null,
  sortBy: null,
  sortAsc: true,
  page: {
    index: 0,
    size: 5
  }
}

export default (state: ChannelList = initialState, action: any): ChannelList => {
  switch (action.type) {
    case actions.FETCH: return fetch(state, action)
    case actions.RECEIVE: return receive(state, action)
    case actions.NEXT_PAGE: return nextPage(state)
    case actions.PREVIOUS_PAGE: return previousPage(state)
    case actions.SORT: return sortItems(state, action)
    case actions.CREATE: return create(state, action)
    default: return state
  }
}

const fetch = (state, action) => {
  return {
    ...state,
    fetching: true,
    sortBy: null,
    sortAsc: true,
    page: {
      index: 0,
      size: 5
    }
  }
}

const receive = (state, action) => {
  const channels = action.channels

  let order = itemsOrder(channels, state.sortBy, state.sortAsc)
  return {
    ...state,
    fetching: false,
    items: channels,
    order
  }
}

const create = (state, action) => {
  return {
    ...state,
    items: {
      ...state.items,
      [action.id]: {
        ...action.channel
      }
    }
  }
}
