import React from 'react'
import { Route } from 'react-router'
import App from './containers/App'
import Studies from './containers/Studies'
import Study from './containers/Study'
import CreateStudy from './containers/CreateStudy'
import EditStudy from './containers/EditStudy'
//import UserPage from './containers/UserPage'
//import RepoPage from './containers/RepoPage'

export default (
  <div>
    <Route path ="/" component={App} />
    <Route path ="/studies" component={Studies} />
    <Route path ="/studies/new" component={CreateStudy} />
    <Route path ="/studies/:id/edit" component={EditStudy} />
    <Route path ="/studies/:id" component={Study} />
  </div>
)
