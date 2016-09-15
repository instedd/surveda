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
import SurveyTabs from './components/SurveyTabs'
import SurveyChannelsStep from './components/SurveyChannelsStep'

export default (
  <Route path="/" component={App} name="Home">
    <IndexRedirect to="projects"/>

    <Route path="projects" name="Projects">
      <IndexRoute component={Projects} />
      <Route path="new" component={CreateProject} name="New Project" />

      <Route path=":projectId" name="Project">
        <IndexRedirect to="surveys"/>
        <Route path="edit" component={EditProject} name="Project" />

        <Route path="surveys" name="Surveys">
          <IndexRoute components={{body: Surveys, tabs: ProjectTabs}} />
          <Route path=":surveyId" components={{body: Survey, tabs: SurveyTabs}} />
          <Route path=":surveyId/edit" component={EditSurvey} >
            <IndexRedirect to="questionnaire"/>
            <Route path="questionnaire" component={SurveyQuestionnaireStep} name="Questionnaire" />
            <Route path="respondents" component={SurveyRespondentsStep} name="Respondents" />
            <Route path="cutoff" component={SurveyCutoffStep} name="Cutoff" />
            <Route path="channels" component={SurveyChannelsStep} name="Channels" />
          </Route>
        </Route>

        <Route path="questionnaires" name="Questionnaires">
          <IndexRoute components={{body: Questionnaires, tabs: ProjectTabs}} />
          <Route path="new" component={CreateQuestionnaire} name="Questionnaire" />
          <Route path=":questionnaireId" name="Questionnaire">
            <IndexRedirect to="edit"/>
          </Route>
          <Route path=":questionnaireId/edit" component={EditQuestionnaire} name="Questionnaire" />
        </Route>

      </Route>

    </Route>

    <Route path="channels" name="Channels">
      <IndexRoute component={Channels} />
    </Route>

  </Route>
)