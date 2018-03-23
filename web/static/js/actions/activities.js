// @flow
import * as api from '../api'

export const RECEIVE_ACTIVITIES = 'ACTIVITIES_RECEIVE'
export const FETCH_ACTIVITIES = 'ACTIVITIES_FETCH'
export const UPDATE_ACTIVITIES_ORDER = 'ACTIVITIES_UPDATE_ORDER'

export const fetchActivities = (projectId: number, page: number) => (dispatch: Function, getState: Function) => {
  const state = getState().activities
  dispatch(startFetchingActivities(projectId, page))
  api.fetchActivities(projectId, state.page.size, page, state.sortBy, state.sortAsc)
    .then(response => {
      dispatch(receiveActivities(projectId, page, response.entities.activities || {}, response.activitiesCount, response.result))
    })
}

export const startFetchingActivities = (projectId: number, page: number) => ({
  type: FETCH_ACTIVITIES,
  projectId,
  page
})

export const receiveActivities = (projectId: number, page: number, activities: IndexedList<any>, activitiesCount: number, order: Array<number>) => ({
  type: RECEIVE_ACTIVITIES,
  projectId,
  page,
  activities,
  activitiesCount,
  order
})

export const sortActivities = (projectId: number) => (dispatch: Function, getState: Function) => {
  const state = getState().activities
  const sortAsc = !state.sortAsc
  api.fetchActivities(projectId, state.page.size, 1, state.sortBy, sortAsc)
    .then(response => dispatch(receiveActivities(projectId, 1, response.entities.activities || {}, response.activitiesCount, response.result)))
  dispatch(updateOrder(sortAsc))
}

export const updateOrder = (sortAsc: boolean) => ({
  type: UPDATE_ACTIVITIES_ORDER,
  sortAsc
})

