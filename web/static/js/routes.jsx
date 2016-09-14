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
import SurveyRespondentsStep from './components/SurveyRespondentsStep'
import SurveyCutoffStep from './components/SurveyCutoffStep'
import Questionnaires from './containers/Questionnaires'
import CreateQuestionnaire from './containers/CreateQuestionnaire'
import Channels from './containers/channels/Channels'
import EditQuestionnaire from './containers/EditQuestionnaire'
import ProjectTabs from './components/ProjectTabs'
import SurveyChannelsStep from './components/SurveyChannelsStep'

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
          <Route path=":surveyId" component={Survey} />
          <Route path=":surveyId/edit" component={EditSurvey} >
            <IndexRedirect to="questionnaire"/>
            <Route path="questionnaire" component={SurveyQuestionnaireStep} />
            <Route path="respondents" component={SurveyRespondentsStep} />
            <Route path="cutoff" component={SurveyCutoffStep} />
            <Route path="channels" component={SurveyChannelsStep} />
          </Route>
        </Route>

        <Route path="questionnaires">
          <IndexRoute components={{body: Questionnaires, tabs: ProjectTabs}} />
          <Route path="new" component={CreateQuestionnaire} />
          <Route path=":questionnaireId">
            <IndexRedirect to="edit"/>
          </Route>
          <Route path=":questionnaireId/edit" component={EditQuestionnaire} />
        </Route>

      </Route>

    </Route>

    <Route path="channels">
      <IndexRoute component={Channels} />
    </Route>

  </Route>
)
