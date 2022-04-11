// @flow
import * as api from "../api"

export const RECEIVE_ACTIVITIES = "ACTIVITIES_RECEIVE"
export const FETCH_ACTIVITIES = "ACTIVITIES_FETCH"

export const fetchActivities =
  (projectId: number, pageSize: number, pageNumber: number, sortAsc: boolean) =>
  (dispatch: Function, getState: Function) => {
    const sortBy = getState().activities.sortBy
    dispatch(startFetchingActivities(projectId, pageSize, pageNumber, sortAsc))
    api.fetchActivities(projectId, pageSize, pageNumber, sortBy, sortAsc).then((response) => {
      const state = getState().activities
      const lastFetchResponse =
        state.projectId == projectId &&
        state.page.size == pageSize &&
        state.page.number == pageNumber &&
        state.sortBy == sortBy &&
        state.sortAsc == sortAsc
      if (lastFetchResponse) {
        dispatch(
          receiveActivities(
            projectId,
            response.entities.activities || {},
            response.activitiesCount,
            response.result
          )
        )
      }
    })
  }

export const startFetchingActivities = (
  projectId: number,
  pageSize: number,
  pageNumber: number,
  sortAsc: boolean
) => ({
  type: FETCH_ACTIVITIES,
  projectId,
  pageSize,
  pageNumber,
  sortAsc,
})

export const receiveActivities = (
  projectId: number,
  activities: Object,
  activitiesCount: number,
  order: Array<number>
) => ({
  type: RECEIVE_ACTIVITIES,
  projectId,
  activities,
  activitiesCount,
  order,
})

export const sortActivities = (projectId: number) => (dispatch: Function, getState: Function) => {
  const { page, sortAsc } = getState().activities
  dispatch(fetchActivities(projectId, page.size, 1, !sortAsc))
}

export const changePageSize =
  (projectId: number, pageSize: number) => (dispatch: Function, getState: Function) => {
    const { sortAsc } = getState().activities
    dispatch(fetchActivities(projectId, pageSize, 1, sortAsc))
  }
