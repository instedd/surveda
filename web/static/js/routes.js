import React from 'react'
import { Route } from 'react-router'
import App from './containers/App'
import Studies from './components/Studies'
//import UserPage from './containers/UserPage'
//import RepoPage from './containers/RepoPage'

export default (
  <div>
    <Route path="/" component={App} />
    <Route path="/studies" component={Studies} />
  </div>
)
