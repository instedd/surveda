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
import Channels from './containers/Channels'
import EditQuestionnaire from './containers/EditQuestionnaire'
import ProjectTabs from './components/ProjectTabs'
import SurveyTabs from './components/SurveyTabs'
import SurveyChannelsStep from './components/SurveyChannelsStep'

export default (
  <Route path="/" component={App} breadcrumbIgnore>
    <IndexRedirect to="projects"/>

    <Route path="/projects" name="My Projects">
      <IndexRoute component={Projects} breadcrumbIgnore />
      <Route path="new" component={CreateProject} name="New Project" />

      <Route path=":projectId" name="Project" breadcrumbName=":projectId">
        <IndexRedirect to="surveys"/>
        <Route path="edit" component={EditProject} breadcrumbIgnore/>

        <Route path="surveys" components={{body: Surveys, tabs: ProjectTabs}} breadcrumbIgnore />

        <Route path="surveys/:surveyId" components={{body: Survey, tabs: SurveyTabs}} breadcrumbName=":surveyId" />
        <Route path="surveys/:surveyId/edit" component={EditSurvey} breadcrumbName=":surveyId">
          <IndexRedirect to="questionnaire"/>
          <Route path="questionnaire" component={SurveyQuestionnaireStep} breadcrumbIgnore />
          <Route path="respondents" component={SurveyRespondentsStep} breadcrumbIgnore />
          <Route path="cutoff" component={SurveyCutoffStep} breadcrumbIgnore />
          <Route path="channels" component={SurveyChannelsStep} breadcrumbIgnore />
        </Route>

        <Route path="questionnaires" breadcrumbIgnore>
          <IndexRoute components={{body: Questionnaires, tabs: ProjectTabs}} breadcrumbIgnore />
          <Route path="new" component={CreateQuestionnaire} name="New Questionnaire" />
          <Route path=":questionnaireId" breadcrumbName=":questionnaireId">
            <IndexRedirect to="edit"/>
          </Route>
          <Route path=":questionnaireId/edit" component={EditQuestionnaire} breadcrumbName=":questionnaireId" />
        </Route>

      </Route>

    </Route>

    <Route path="/channels" name="My Channels" >
      <IndexRoute component={Channels} breadcrumbIgnore />
    </Route>

  </Route>
)
