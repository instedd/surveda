import React from 'react'
import { Route, IndexRoute } from 'react-router'
import App from './containers/App'
import Projects from './containers/Projects'
import Project from './containers/Project'
import CreateProject from './containers/CreateProject'
import EditProject from './containers/EditProject'
import Surveys from './containers/Surveys'
import Survey from './containers/Survey'
//import UserPage from './containers/UserPage'
//import RepoPage from './containers/RepoPage'

export default (
  <div>
    <Route path ="/" component={App}>
      <Route path="projects">
        <IndexRoute component={Projects} />
        <Route path="new" component={CreateProject} />
        <Route path=":projectId">
          <IndexRoute component={Project} />
          <Route path="edit" component={EditProject} />
          <Route path="surveys">
            <IndexRoute component={Surveys} />
            <Route path=":surveyId" component={Survey} />
          </Route>
        </Route>
      </Route>
    </Route>
  </div>
)
