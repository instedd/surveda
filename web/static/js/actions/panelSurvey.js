// @flow
import * as api from '../api'
import * as panelSurveysActions from '../actions/panelSurveys'

export const FETCH = 'PANEL_SURVEY_FETCH'
export const RECEIVE = 'PANEL_SURVEY_RECEIVE'

export const createPanelSurvey = (projectId: number, folderId?: number) => (dispatch: Function, getState: () => Store) =>
  api.createSurvey(projectId, folderId, true).then(response => {
    const firstOccurrence = response.result
    dispatch(fetch(projectId, firstOccurrence.id))
    dispatch(receive(firstOccurrence))
    return firstOccurrence
  })

export const fetchPanelSurvey = (projectId: number, id: number) => (dispatch: Function, getState: () => Store): Survey => {
  dispatch(fetch(projectId, id))
  return api.fetchPanelSurvey(projectId, id)
    .then(response => {
      dispatch(receive(response.entities.panelSurveys[response.result]))
    })
    .then(() => {
      return getState().panelSurvey.data
    })
}

export const fetch = (projectId: number, id: number): FilteredAction => ({
  type: FETCH,
  id,
  projectId
})

export const receive = (panelSurvey: PanelSurvey) => ({
  type: RECEIVE,
  data: panelSurvey
})

export const changeFolder = (panelSurvey: PanelSurvey, folderId: number) => (dispatch: Function, getState: () => Store) => {
  return api.panelSurveySetFolderId(panelSurvey.projectId, panelSurvey.id, folderId)
    .then(() => dispatch(panelSurveysActions.folderChanged(panelSurvey.id, folderId)))
}
