import 'babel-polyfill'
import React from 'react'
import { render } from 'react-dom'
import { browserHistory } from 'react-router'
import { syncHistoryWithStore } from 'react-router-redux'
import Root from './containers/Root'
import configureStore from './store/configureStore'

const store = configureStore()
const history = syncHistoryWithStore(browserHistory, store)

render(
  <div>
    <h1>Welcome to Ask!</h1>
    <Root store={store} history={history} />
  </div>,
  document.getElementById('root')
)

