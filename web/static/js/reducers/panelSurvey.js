// @flow
import * as actions from '../actions/panelSurvey'
import fetchReducer from './fetch'

export const dataReducer = (state: PanelSurvey, action: any): PanelSurvey => {
  switch (action.type) {
    default: return state
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
