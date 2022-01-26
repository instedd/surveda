import * as api from '../api'
import * as panelSurveyActions from './panelSurvey'

export const FETCH = 'FETCH_PANEL_SURVEYS'
export const RECEIVE = 'RECEIVE_PANEL_SURVEYS'
export const FOLDER_CHANGED = 'PANEL_SURVEY_FOLDER_CHANGED'

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

export const updateStore = (dispatch, projectId, panelSurveyId) => {
  dispatch(panelSurveyActions.fetchPanelSurvey(projectId, panelSurveyId))
  dispatch(fetchPanelSurveys(projectId))
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

export const folderChanged = (panelSurveyId: number, folderId: number) => ({
  type: FOLDER_CHANGED,
  panelSurveyId,
  folderId
})
