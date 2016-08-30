import React from 'react'
import { Route } from 'react-router'
import App from './containers/App'
import Projects from './containers/Projects'
import Project from './containers/Project'
import CreateProject from './containers/CreateProject'
import EditProject from './containers/EditProject'
//import UserPage from './containers/UserPage'
//import RepoPage from './containers/RepoPage'

export default (
  <div>
    <Route path ="/" component={App} />
    <Route path ="/projects" component={Projects} />
    <Route path ="/projects/new" component={CreateProject} />
    <Route path ="/projects/:id/edit" component={EditProject} />
    <Route path ="/projects/:id" component={Project} />
  </div>
)
