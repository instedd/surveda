// @flow
import React from 'react'
import { render } from 'react-dom'
import Root from './components/layout/Root'
import configureStore from './store/configureStore'

const store = configureStore()

const root = document.getElementById('root')
if (root) {
  render(<Root store={store} />, root)
}

