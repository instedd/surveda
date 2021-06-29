// @flow
import * as actions from '../actions/panelSurvey'
import * as surveyActions from '../actions/surveys'
import fetchReducer from './fetch'

export const dataReducer = (state: PanelSurvey, action: any): PanelSurvey => {
  switch (action.type) {
    case surveyActions.DELETED: return deleteSurvey(state, action)
    default: return state
  }
}

const deleteSurvey = (state, action) => {
  const occurrences = state.occurrences
  ? state.occurrences.filter(occurrence => occurrence.id != action.id)
  : state.occurrences
  return {
    ...state,
    occurrences: occurrences
  }
}

const dirtyPredicate = (action, oldData, newData) => {
  switch (action.type) {
    default: return true
  }
}

const validateReducer = (reducer: StoreReducer<PanelSurvey>): StoreReducer<PanelSurvey> => {
  return (state: ?DataStore<PanelSurvey>, action: any) => {
    const newState = reducer(state, action)
    return newState
  }
}

export default validateReducer(fetchReducer(actions, dataReducer, null, dirtyPredicate))
