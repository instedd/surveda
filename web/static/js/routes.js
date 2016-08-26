import React from 'react'
import { Route } from 'react-router'
import App from './containers/App'
import Studies from './containers/Studies'
import Study from './containers/Study'
import StudyForm from './containers/StudyForm'
//import UserPage from './containers/UserPage'
//import RepoPage from './containers/RepoPage'

export default (
  <div>
    <Route path ="/" component={App} />
    <Route path ="/studies" component={Studies} />
    <Route path ="/studies/new" component={StudyForm} />
    <Route path ="/studies/:id" component={Study} />
  </div>
)
