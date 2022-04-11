import { createStore, applyMiddleware, compose } from "redux"
import thunkMiddleware from "redux-thunk"
import { routerMiddleware } from "react-router-redux"
import rootReducer from "../reducers"
import autosave from "./autosave"
import * as questionnaireActions from "../actions/questionnaire"
import * as surveyActions from "../actions/survey"

export default function configureStore(preState, middlewares = [], enhancers = []) {
  return createStore(
    rootReducer,
    preState,
    compose(
      applyMiddleware(
        thunkMiddleware,
        routerMiddleware(),
        autosave((store) => store.questionnaire, questionnaireActions),
        autosave((store) => store.survey, surveyActions),
        ...middlewares
      ),
      ...enhancers
    )
  )
}
