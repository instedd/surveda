import { createStore, applyMiddleware, compose } from 'redux'
import createLogger from 'redux-logger'
import { routerMiddleware } from 'react-router-redux';
import reducers from '../reducers';
import DevTools from '../containers/DevTools'

const loggerMiddleware = createLogger({
  level: 'info',
  collapsed: true,
});

export default function configureStore(browserHistory) {
  const reduxRouterMiddleware = routerMiddleware(browserHistory);
  const createStoreWithMiddleware = compose(applyMiddleware(reduxRouterMiddleware, loggerMiddleware), DevTools.instrument())(createStore);

  return createStoreWithMiddleware(reducers);
}
