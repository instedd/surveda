import * as actions from '../actions/panelSurveys'

const initialState = {
  fetching: false,
  items: null,
  projectId: null
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.FETCH_PANEL_SURVEYS: return fetchPanelSurveys(state, action)
    case actions.RECEIVE_PANEL_SURVEYS: return receivePanelSurveys(state, action)
    default: return state
  }
}

const receivePanelSurveys = (state, action) => {
  return {
    ...state,
    fetching: false,
    projectId: action.projectId,
    items: action.panelSurveys
  }
}

const fetchPanelSurveys = (state, action) => {
  const items = state.projectId == action.projectId ? state.items : null
  return {
    ...state,
    items,
    fetching: true,
    projectId: action.projectId
  }
}
