import 'babel-polyfill'
import 'jquery'
import './errors'
import React from 'react'
import { render } from 'react-dom'
import { browserHistory } from 'react-router'
import { syncHistoryWithStore } from 'react-router-redux'
import Root from './components/layout/Root'
import configureStore from './store/configureStore'

const store = configureStore()
const history = syncHistoryWithStore(browserHistory, store)

const root = document.getElementById('root')
if (root) {
  render(<Root store={store} history={history} />, root)
}
