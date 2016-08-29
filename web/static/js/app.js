import 'babel-polyfill'
import React from 'react'
import { render } from 'react-dom'
import { browserHistory } from 'react-router'
import { syncHistoryWithStore } from 'react-router-redux'
import Root from './containers/Root'
import Header from './components/Header'
import Footer from './components/Footer'
import configureStore from './store/configureStore'

const store = configureStore()
const history = syncHistoryWithStore(browserHistory, store)

render(
  <div>
    <div style={{width: '50%', margin: '0 auto'}}>
      <Header />
      <Root store={store} history={history} />
      <Footer />
    </div>
  </div>,
  document.getElementById('root')
)
