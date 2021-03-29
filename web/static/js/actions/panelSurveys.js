import * as api from '../api'

export const RECEIVE_PANEL_SURVEYS = 'RECEIVE_PANEL_SURVEYS'
export const FETCH_PANEL_SURVEYS = 'FETCH_PANEL_SURVEYS'

export const fetchPanelSurveys = (projectId) => dispatch => {
  dispatch(startFetchingPanelSurveys(projectId))
  api.fetchPanelSurveys(projectId)
    .then(response => {
      dispatch(receivePanelSurveys(response, projectId))
    })
}

export const receivePanelSurveys = (panelSurveys, projectId) => ({
  type: RECEIVE_PANEL_SURVEYS,
  projectId,
  panelSurveys
})

export const startFetchingPanelSurveys = (projectId) => ({
  type: FETCH_PANEL_SURVEYS,
  projectId
})
