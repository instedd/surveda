// @flow
import isEqual from 'lodash/isEqual'
import toInteger from 'lodash/toInteger'
import values from 'lodash/values'

const initialState = {
  fetching: false,
  filter: null,
  items: null,
  order: null,
  sortBy: null,
  sortAsc: true,
  page: {
    index: 0,
    size: 5
  }
}

const defaultFilterProvider = (action) => ({
  projectId: toInteger(action.projectId)
})

export default (actions: any, itemsReducer: Reducer<any>, filterProvider: (action: FilteredAction) => any = defaultFilterProvider) => (state: ?ListStore<any>, action: any): ListStore<any> => {
  state = state || initialState
  switch (action.type) {
    case actions.FETCH: return fetch(state, action, filterProvider)
    case actions.RECEIVE: return receive(state, action, filterProvider)
    case actions.NEXT_PAGE: return nextPage(state)
    case actions.PREVIOUS_PAGE: return previousPage(state)
    case actions.SORT: return sortItems(state, action)
    default: return items(state, action, itemsReducer)
  }
}

const items = (state, action, itemsReducer) => {
  const newItems: any = state.items == null ? null : itemsReducer(state.items, action)

  if (newItems !== state.items) {
    return ({
      ...state,
      items: newItems
    })
  }

  return state
}

const receive = (state: ListStore<any>, action: ReceiveItemsAction, filterProvider) => {
  const items = action.items
  const itemsFilter = filterProvider(items)

  if (isEqual(state.filter, itemsFilter)) {
    const items = action.items
    let order = itemsOrder(items, state.sortBy, state.sortAsc)
    return {
      ...state,
      fetching: false,
      items: items,
      order
    }
  }

  return state
}

const fetch = (state, action, filterProvider) => {
  const newFilter = filterProvider(action)

  let newItems = null

  if (isEqual(state.filter, newFilter)) {
    newItems = state.items
  }

  return {
    ...state,
    fetching: true,
    filter: newFilter,
    items: newItems,
    sortBy: null,
    sortAsc: true,
    page: {
      index: 0,
      size: 5
    }
  }
}

const itemsOrder = (items, sortBy, sortAsc) => {
  const itemsValues = values(items)

  if (sortBy) {
    itemsValues.sort((p1, p2) => {
      let x1 = p1[sortBy]
      let x2 = p2[sortBy]

      if (typeof (x1) == 'string') {
        x1 = x1.toLowerCase()
        if (x2 == null) x2 = 'untitled'
      }
      if (typeof (x2) == 'string') {
        x2 = x2.toLowerCase()
        if (x1 == null) x1 = 'untitled'
      }

      if (x1 < x2) {
        return sortAsc ? -1 : 1
      } else if (x1 > x2) {
        return sortAsc ? 1 : -1
      } else {
        return 0
      }
    })
  }

  return itemsValues.map(p => p.id)
}

const sortItems = (state: ListStore<any>, action: any) => {
  const sortAsc = state.sortBy == action.property ? !state.sortAsc : true
  const sortBy = action.property
  const order = itemsOrder(state.items, sortBy, sortAsc)
  return {
    ...state,
    order,
    sortBy,
    sortAsc
  }
}

const nextPage = (state: ListStore<any>) => ({
  ...state,
  page: {
    ...state.page,
    index: state.page.index + state.page.size
  }
})

const previousPage = (state: ListStore<any>) => ({
  ...state,
  page: {
    ...state.page,
    index: state.page.index - state.page.size
  }
})

export const orderedItems = (items: IndexedList<any>, order: string[]) => {
  if (items && order) {
    return order.map(id => items[id])
  } else {
    return null
  }
}
