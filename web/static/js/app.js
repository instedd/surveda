import 'babel-polyfill'
import React from 'react'
import { render } from 'react-dom'
import { browserHistory } from 'react-router'
import { syncHistoryWithStore } from 'react-router-redux'
import Root from './containers/Root'
import configureStore from './store/configureStore'
import MuiThemeProvider from 'material-ui/styles/MuiThemeProvider';

const store = configureStore()
const history = syncHistoryWithStore(browserHistory, store)

render(
  <MuiThemeProvider>
    <div style={{width: '50%', margin: '0 auto'}}>
      <Root store={store} history={history} />
    </div>
  </MuiThemeProvider>,
  document.getElementById('root')
)
