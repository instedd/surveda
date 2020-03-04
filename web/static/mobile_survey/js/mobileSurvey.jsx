// @flow
import React from 'react'
import { render } from 'react-dom'
import Root from './components/layout/Root'
import configureStore from './store/configureStore'

const root = document.getElementById('root')
if (root) {
  const configAttr = root.getAttribute('data-config')
  if (configAttr) {
    const config = JSON.parse(configAttr)
    const store = configureStore({config})
    render(<Root store={store} />, root)
  } else {
    console.error("Missing data-config in root element", root)
  }
}
