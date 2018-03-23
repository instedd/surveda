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
    case actions.UPDATE_ACTIVITIES_ORDER: return updateActivitiesOrder(state, action)
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
    page: {
      ...state.page,
      number: action.page
    }
  }
}

const receiveActivities = (state, action) => {
  if (state.projectId != action.projectId || state.page.number != action.page) {
    return state
  }

  return {
    ...state,
    fetching: false,
    items: action.activities,
    order: action.order,
    page: {
      ...state.page,
      number: action.page,
      totalCount: action.activitiesCount
    }
  }
}

const updateActivitiesOrder = (state, action) => {
  return {
    ...state,
    page: {
      ...state.page,
      number: 1
    },
    sortAsc: action.sortAsc
  }
}
