// @flow
import * as actions from "../actions/panelSurvey"
import * as surveyActions from "../actions/survey"
import * as surveysActions from "../actions/surveys"
import fetchReducer from "./fetch"

export const dataReducer = (state: PanelSurvey, action: any): PanelSurvey => {
  switch (action.type) {
    default:
      return state
  }
}

const dirtyPredicate = (action, oldData, newData) => {
  switch (action.type) {
    default:
      return true
  }
}

const validateReducer = (reducer: StoreReducer<PanelSurvey>): StoreReducer<PanelSurvey> => {
  return (state: ?DataStore<PanelSurvey>, action: any) => {
    const newState = reducer(state, action)

    switch (action.type) {
      case surveyActions.CHANGE_NAME:
        // A wave of the panel survey was renamed (the panel survey has changed):
        // the Redux store must eventually be updated with the panel survey new
        // state
        newState.dirty = true
        break

      case surveysActions.DELETED:
        // A wave of the panel survey was deleted, we must remove the wave from
        // the list of waves, and update the latestWave accordingly:
        const panelSurvey = newState.data
        if (panelSurvey) {
          const index = panelSurvey.waves.findIndex((s) => s.id == action.id)
          if (index >= 0) {
            panelSurvey.waves.splice(index, 1)
            panelSurvey.latestWave = panelSurvey.waves[0]
          }
        }
        break
    }

    return newState
  }
}

export default validateReducer(fetchReducer(actions, dataReducer, null, dirtyPredicate))
