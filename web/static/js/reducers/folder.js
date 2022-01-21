// @flow
import * as actions from '../actions/folder'
import * as surveysActions from '../actions/surveys'

const initialState = {
  fetching: false,
  error: null
}

export default (state: any = initialState, action: any) => {
  switch (action.type) {
    case actions.FETCH:
      return {
        ...state,
        fetching: true
      }
    case actions.RECEIVE:
      return {
        ...state,
        data: action.data,
        fetching: false
      }
    case surveysActions.DELETED:
      return removeSurvey(state, action.id)
    case surveysActions.FOLDER_CHANGED:
      return removeSurvey(state, action.surveyId)
  }
  return state
}

function removeSurvey(state, surveyId) {
  const folder = state.data

  if (folder) {
    const surveys = [].concat(folder.surveys || [])
    const index = surveys.findIndex(s => s.id == surveyId)

    if (index >= 0) {
      surveys.splice(index, 1)
      return {...state, data: {...folder, surveys: surveys}}
    }
  }
  return state
}
