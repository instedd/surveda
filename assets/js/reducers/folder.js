// @flow
import * as actions from "../actions/folder"
import * as surveysActions from "../actions/surveys"
import * as panelSurveysActions from "../actions/panelSurveys"

const initialState = {
  fetching: false,
  error: null,
}

export default (state: any = initialState, action: any) => {
  switch (action.type) {
    case actions.FETCH:
      return {
        ...state,
        fetching: true,
      }
    case actions.RECEIVE:
      return {
        ...state,
        data: action.data,
        fetching: false,
      }
    case surveysActions.DELETED:
      return removeSurvey(state, action.id)
    case surveysActions.FOLDER_CHANGED:
      return removeSurvey(state, action.surveyId)
    case panelSurveysActions.DELETED:
      return removePanelSurvey(state, action.id)
    case panelSurveysActions.FOLDER_CHANGED:
      return removePanelSurvey(state, action.panelSurveyId)
  }
  return state
}

function removeSurvey(state, surveyId) {
  const folder = state.data

  if (folder) {
    const surveys = [].concat(folder.surveys || [])
    const index = surveys.findIndex((s) => s.id == surveyId)

    if (index >= 0) {
      surveys.splice(index, 1)
      return { ...state, data: { ...folder, surveys: surveys } }
    }
  }
  return state
}

function removePanelSurvey(state, panelSurveyId) {
  const folder = state.data

  if (folder) {
    const panelSurveys = [].concat(folder.panelSurveys || [])
    const index = panelSurveys.findIndex((s) => s.id == panelSurveyId)

    if (index >= 0) {
      panelSurveys.splice(index, 1)
      return { ...state, data: { ...folder, panelSurveys: panelSurveys } }
    }
  }
  return state
}
