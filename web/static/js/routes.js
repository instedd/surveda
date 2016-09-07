import React from 'react'
import { Route, IndexRoute, IndexRedirect } from 'react-router'
import App from './containers/App'
import Projects from './containers/Projects'
import CreateProject from './containers/CreateProject'
import EditProject from './containers/EditProject'
import EditSurvey from './containers/EditSurvey'
import Surveys from './containers/Surveys'
import Survey from './containers/Survey'
import SurveyQuestionnaireStep from './components/SurveyQuestionnaireStep'
import Questionnaires from './containers/Questionnaires'
import CreateQuestionnaire from './containers/CreateQuestionnaire'
import Channels from './containers/channels/Channels'
import EditQuestionnaire from './containers/EditQuestionnaire'
import ProjectTabs from './components/ProjectTabs'
//import UserPage from './containers/UserPage'
//import RepoPage from './containers/RepoPage'

export default (
  <Route path="/" component={App}>
    <IndexRedirect to="projects"/>

    <Route path="projects">
      <IndexRoute component={Projects} />
      <Route path="new" component={CreateProject} />

      <Route path=":projectId">
        <IndexRedirect to="surveys"/>
        <Route path="edit" component={EditProject} />

        <Route path="surveys">
          <IndexRoute components={{body: Surveys, tabs: ProjectTabs}} />
          <Route path=":id" component={Survey} />
          <Route path=":id/edit" component={EditSurvey} >
            <IndexRedirect to="questionnaire"/>
            <Route path="questionnaire" component={SurveyQuestionnaireStep} />
          </Route>
        </Route>

        <Route path="questionnaires">
          <IndexRoute components={{body: Questionnaires, tabs: ProjectTabs}} />
          <Route path="new" component={CreateQuestionnaire} />
          <Route path=":id">
            <IndexRedirect to="edit"/>
          </Route>
          <Route path=":id/edit" component={EditQuestionnaire} />
        </Route>

      </Route>

    </Route>

    <Route path="channels">
     <IndexRoute component={Channels} />
    </Route>

  </Route>
)
