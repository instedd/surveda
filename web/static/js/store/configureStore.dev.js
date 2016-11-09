import DevTools from '../components/DevTools'
import prodStore from './configureStore.prod'

export default function configureStore(preloadedState) {
  return prodStore(preloadedState, [DevTools.instrument()])
}
