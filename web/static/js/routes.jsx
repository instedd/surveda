import React from 'react'
import { Route, IndexRoute, IndexRedirect } from 'react-router'
import App from './containers/App'
import ProjectIndex from './containers/ProjectIndex'
import ProjectNew from './containers/ProjectNew'
import ProjectEdit from './containers/ProjectEdit'
import SurveyEdit from './containers/SurveyEdit'
import SurveyIndex from './containers/SurveyIndex'
import SurveyShow from './containers/SurveyShow'
import SurveyWizardQuestionnaireStep from './containers/SurveyWizardQuestionnaireStep'
import SurveyWizardRespondentsStep from './containers/SurveyWizardRespondentsStep'
import SurveyWizardCutoffStep from './containers/SurveyWizardCutoffStep'
import SurveyWizardChannelsStep from './containers/SurveyWizardChannelsStep'
import QuestionnaireIndex from './containers/QuestionnaireIndex'
import QuestionnaireNew from './containers/QuestionnaireNew'
import ChannelIndex from './containers/ChannelIndex'
import QuestionnaireEdit from './containers/QuestionnaireEdit'
import ProjectTabs from './components/ProjectTabs'
import SurveyTabs from './components/SurveyTabs'

export default (
  <Route path="/" component={ App } breadcrumbIgnore>
    <IndexRedirect to="projects"/>

    <Route path="/projects" name="My Projects">
      <IndexRoute component={ ProjectIndex } breadcrumbIgnore />
      <Route path="new" component={ ProjectNew } name="New Project" />

      <Route path=":projectId" name="Project" breadcrumbName=":projectId">
        <IndexRedirect to="surveys"/>
        <Route path="edit" component={ ProjectEdit } breadcrumbIgnore/>

        <Route path="surveys" components={{ body: SurveyIndex, tabs: ProjectTabs }} breadcrumbIgnore />

        <Route path="surveys/:surveyId" components={{ body: SurveyShow, tabs: SurveyTabs }} breadcrumbName=":surveyId" />
        <Route path="surveys/:surveyId/edit" component={ SurveyEdit } breadcrumbName=":surveyId">
          <IndexRedirect to="questionnaire"/>
          <Route path="questionnaire" component={ SurveyWizardQuestionnaireStep } breadcrumbIgnore />
          <Route path="respondents" component={ SurveyWizardRespondentsStep } breadcrumbIgnore />
          <Route path="cutoff" component={ SurveyWizardCutoffStep } breadcrumbIgnore />
          <Route path="channels" component={ SurveyWizardChannelsStep } breadcrumbIgnore />
        </Route>

        <Route path="questionnaires" breadcrumbIgnore>
          <IndexRoute components={{ body: QuestionnaireIndex, tabs: ProjectTabs }} breadcrumbIgnore />
          <Route path="new" component={ QuestionnaireNew } name="New Questionnaire" />
          <Route path=":questionnaireId" breadcrumbName=":questionnaireId">
            <IndexRedirect to="edit"/>
          </Route>
          <Route path=":questionnaireId/edit" component={ QuestionnaireEdit } breadcrumbName=":questionnaireId" />
        </Route>

      </Route>

    </Route>

    <Route path="/channels" name="My Channels" >
      <IndexRoute component={ ChannelIndex } breadcrumbIgnore />
    </Route>

  </Route>
)
