import * as actions from '../actions/activities'

const initialState = {
  fetching: false,
  items: null,
  order: [],
  projectId: null,
  sortBy: 'insertedAt',
  sortAsc: false,
  page: {
    number: 1,
    size: 15,
    totalCount: 0
  }
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.FETCH_ACTIVITIES: return fetchActivities(state, action)
    case actions.RECEIVE_ACTIVITIES: return receiveActivities(state, action)
    default: return state
  }
}

const fetchActivities = (state, action) => {
  const sameProject = state.projectId == action.projectId

  const items = sameProject ? state.items : null
  return {
    ...state,
    items,
    projectId: action.projectId,
    fetching: true,
    sortAsc: sameProject ? action.sortAsc : false,
    page: {
      ...state.page,
      size: action.pageSize,
      number: action.pageNumber
    }
  }
}

const receiveActivities = (state, action) => ({
  ...state,
  fetching: false,
  items: action.activities,
  order: action.order,
  page: {
    ...state.page,
    totalCount: action.activitiesCount
  }
})
