import { createStore, applyMiddleware, compose } from 'redux'
import createLogger from 'redux-logger'
import { routerMiddleware } from 'react-router-redux';
import reducers from '../reducers';

const loggerMiddleware = createLogger({
  level: 'info',
  collapsed: true,
});

export default function configureStore(browserHistory) {
  const reduxRouterMiddleware = routerMiddleware(browserHistory);
  const createStoreWithMiddleware = applyMiddleware(reduxRouterMiddleware, loggerMiddleware)(createStore);

  return createStoreWithMiddleware(reducers);
}
