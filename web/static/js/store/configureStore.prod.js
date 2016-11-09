import { createStore, applyMiddleware, compose } from 'redux'
import thunkMiddleware from 'redux-thunk'
import { routerMiddleware } from 'react-router-redux'
import rootReducer from '../reducers'
import autosave from './autosave'
import * as questionnaireActions from '../actions/questionnaire'
import * as surveyActions from '../actions/survey'
import createLogger from 'redux-logger'

export default function configureStore(preState, enhancers = [], middlewares = []) {
  return createStore(
    rootReducer,
    preState,
    compose(
      applyMiddleware(
        thunkMiddleware,
        routerMiddleware(),
        createLogger(),
        autosave((store) => store.questionnaire, questionnaireActions),
        autosave((store) => store.survey, surveyActions),
        ...middlewares),
      ...enhancers)
  )
}
