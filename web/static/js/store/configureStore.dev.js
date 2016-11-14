import prodStore from './configureStore.prod'
import createLogger from 'redux-logger'

export default function configureStore(preloadedState) {
  return prodStore(preloadedState, [createLogger()])
}
