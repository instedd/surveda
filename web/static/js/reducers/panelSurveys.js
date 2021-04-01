import * as actions from '../actions/panelSurveys'
import collectionReducer, { projectFilterProvider } from './collection'

const itemsReducer = (state: IndexedList<PanelSurvey>, action): IndexedList<PanelSurvey> => {
  switch (action.type) {
    default: return state
  }
}

const initialState = {
  fetching: false,
  items: null,
  projectId: null
}

export default collectionReducer(actions, itemsReducer, projectFilterProvider, initialState)
