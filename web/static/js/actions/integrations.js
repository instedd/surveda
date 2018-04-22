// @flow
import * as api from '../api'
import { project } from '../routes';

export const RECEIVE = 'INTEGRATIONS_RECEIVE'
export const FETCH = 'INTEGRATIONS_FETCH'

export const fetchIntegrations = (projectId: number, surveyId: number) => (dispatch: Function, getState: () => Store): Promise<?IntegrationList> => {
  const state = getState()

  // Don't fetch integrations if they are already being fetched
  // for that same project and survey
  if (state.integrations.fetching &&
      state.integrations.filter &&
      state.integrations.filter.projectId == projectId &&
      state.integrations.filter.surveyId == surveyId) {
    return Promise.resolve(getState().integrations.items)
  }

  dispatch(startFetchingIntegrations(projectId, surveyId))

  return api
    .fetchIntegrations(projectId, surveyId)
    .then(response => dispatch(receiveIntegrations(projectId, surveyId, response.entities.integrations || {})))
    .then(() => getState().integrations.items)
}

export const startFetchingIntegrations = (projectId: number, surveyId: number) => ({
  type: FETCH,
  projectId,
  surveyId
})

export const receiveIntegrations = (projectId: number, surveyId: number, items: IndexedList<Integration>): ReceiveItemsAction => {
  return {
    type: RECEIVE,
    projectId,
    surveyId,
    items
  }
}
