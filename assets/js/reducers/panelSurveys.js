import * as actions from "../actions/panelSurveys"
import collectionReducer, { projectFilterProvider } from "./collection"

const itemsReducer = (state: IndexedList<PanelSurvey>, action): IndexedList<PanelSurvey> => {
  switch (action.type) {
    case actions.DELETED:
      return removeItem(state, action.id)
    case actions.FOLDER_CHANGED:
      return removeItem(state, action.panelSurveyId)
    default:
      return state
  }
}

const removeItem = (items: IndexedList<PanelSurvey>, panelSurveyId: number) => {
  if (items[panelSurveyId]) {
    items = { ...items }
    delete items[panelSurveyId]
  }
  return items
}

const initialState = {
  fetching: false,
  items: null,
  projectId: null,
}

export default collectionReducer(actions, itemsReducer, projectFilterProvider, initialState)
