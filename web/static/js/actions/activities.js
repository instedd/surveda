// @flow
import * as api from '../api'

export const RECEIVE = 'ACTIVITIES_RECEIVE'
export const FETCH = 'ACTIVITIES_FETCH'
export const NEXT_PAGE = 'ACTIVITIES_NEXT_PAGE'
export const PREVIOUS_PAGE = 'ACTIVITIES_PREVIOUS_PAGE'
export const SORT = 'ACTIVITIES_SORT'

export const fetchActivities = (projectId: number) => (dispatch: Function) => {
  dispatch(startFetchingActivities(projectId))
  api.fetchActivities(projectId)
    .then(response => {
      dispatch(receiveActivities(projectId, response.entities.activities))
    })
}

export const startFetchingActivities = (projectId: number) => ({
  type: FETCH,
  projectId
})

export const receiveActivities = (projectId: number, items: IndexedList<any>): ReceiveFilteredItemsAction => ({
  type: RECEIVE,
  projectId,
  items
})

export const nextActivitiesPage = () => ({
  type: NEXT_PAGE
})

export const previousActivitiesPage = () => ({
  type: PREVIOUS_PAGE
})

export const sortActivitiesBy = (property: string) => ({
  type: SORT,
  property
})

