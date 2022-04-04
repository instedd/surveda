import { createStore, applyMiddleware, compose } from "redux"
import rootReducer from "../reducers"

export default function configureStore(preState, middlewares = [], enhancers = []) {
  return createStore(rootReducer, preState, compose(applyMiddleware(...middlewares), ...enhancers))
}
