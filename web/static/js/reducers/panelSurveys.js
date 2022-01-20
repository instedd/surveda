import * as actions from '../actions/panelSurveys'
import collectionReducer, { projectFilterProvider } from './collection'

const itemsReducer = (state: IndexedList<PanelSurvey>, action): IndexedList<PanelSurvey> => {
  switch (action.type) {
    case actions.FOLDER_CHANGED: return changeFolder(state, action)
    default: return state
  }
}

const changeFolder = (state: IndexedList<PanelSurvey>, action: any) => {
  const items = { ...state }
  delete items[action.panelSurveyId]

  return items
}

const initialState = {
  fetching: false,
  items: null,
  projectId: null
}

export default collectionReducer(actions, itemsReducer, projectFilterProvider, initialState)
