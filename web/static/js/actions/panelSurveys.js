import * as api from '../api'

export const FETCH = 'PANEL_SURVEYS_FETCH'
export const RECEIVE = 'PANEL_SURVEYS_RECEIVE'

export const fetchPanelSurveys = (projectId: number) => (dispatch: Function, getState: () => Store): Promise<?SurveyList> => {
  const state = getState()
  // Don't fetch panel surveys if they are already being fetched for that same project
  if (state.panelSurveys.fetching && state.panelSurveys.filter && state.panelSurveys.filter.projectId == projectId) {
    return Promise.resolve(getState().panelSurveys.items)
  }
  dispatch(startFetchingPanelSurveys(projectId))

  return api
    .fetchPanelSurveys(projectId)
    .then(response => dispatch(receivePanelSurveys(projectId, response.entities.panelSurveys || {})))
    .then(() => getState().panelSurveys.items)
}

export const startFetchingPanelSurveys = (projectId: number) => ({
  type: FETCH,
  projectId
})

export const receivePanelSurveys = (projectId: number, items: IndexedList<PanelSurvey>): ReceiveFilteredItemsAction => ({
  type: RECEIVE,
  projectId,
  items
})
