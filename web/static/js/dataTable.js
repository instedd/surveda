import values from 'lodash/values'

export const itemsOrder = (items, sortBy, sortAsc) => {
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

export const sortItems = (state, action) => {
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

export const orderedItems = (items, order) => {
  if (items && order) {
    return order.map(id => items[id])
  } else {
    return null
  }
}

export const nextPage = (state) => ({
  ...state,
  page: {
    ...state.page,
    index: state.page.index + state.page.size
  }
})

export const previousPage = (state) => ({
  ...state,
  page: {
    ...state.page,
    index: state.page.index - state.page.size
  }
})
