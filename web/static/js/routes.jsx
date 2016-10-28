import React from 'react'
import { Route, IndexRoute, IndexRedirect } from 'react-router'
import App from './components/layout/App'
import ProjectIndex from './components/projects/ProjectIndex'
import SurveyEdit from './components/surveys/SurveyEdit'
import SurveyIndex from './components/surveys/SurveyIndex'
import SurveyShow from './components/surveys/SurveyShow'
import QuestionnaireIndex from './components/questionnaires/QuestionnaireIndex'
import QuestionnaireEditor from './components/questionnaires/QuestionnaireEditor'
import ChannelIndex from './components/ChannelIndex'
import ProjectTabs from './components/projects/ProjectTabs'
import SurveyTabs from './components/surveys/SurveyTabs'
import RespondentIndex from './components/respondents/RespondentIndex'
import ProjectTitle from './components/projects/ProjectTitle'
import SurveyTitle from './components/surveys/SurveyTitle'
import QuestionnaireTitle from './components/questionnaires/QuestionnaireTitle'

export default (
  <Route path='/' component={App}>
    <IndexRedirect to='projects' />

    <Route path='/projects' title='My Projects'>
      <IndexRoute component={ProjectIndex} />

      <Route path=':projectId' title={ProjectTitle}>
        <IndexRedirect to='surveys' />

        <Route path='surveys'>
          <IndexRoute components={{ body: SurveyIndex, tabs: ProjectTabs }} />

          <Route path=':surveyId' title={SurveyTitle}>
            <IndexRoute components={{ body: SurveyShow, tabs: SurveyTabs }} />
            <Route path='respondents' components={{ body: RespondentIndex, tabs: SurveyTabs }} />
            <Route path='edit' component={SurveyEdit} />
          </Route>
        </Route>

        <Route path='questionnaires' >
          <IndexRoute components={{ body: QuestionnaireIndex, tabs: ProjectTabs }} />
          <Route path='new' component={QuestionnaireEditor} title={QuestionnaireTitle} />
          <Route path=':questionnaireId' >
            <IndexRedirect to='edit' />
          </Route>
          <Route path=':questionnaireId/edit' component={QuestionnaireEditor} title={QuestionnaireTitle} />
        </Route>

      </Route>
    </Route>

    <Route path='/channels' title='My Channels' >
      <IndexRoute component={ChannelIndex} />
    </Route>
  </Route>
)

export const root = '/'
export const projects = '/projects'
export const project = (id) => `${projects}/${id}`
export const surveys = (projectId) => `${project(projectId)}/surveys`
export const survey = (projectId, surveyId) => `${surveys(projectId)}/${surveyId}`
export const surveyRespondents = (projectId, surveyId) => `${survey(projectId, surveyId)}/respondents`
export const editSurvey = (projectId, surveyId) => `${survey(projectId, surveyId)}/edit`
export const questionnaires = (projectId) => `${project(projectId)}/questionnaires`
export const newQuestionnaire = (projectId) => `${questionnaires(projectId)}/new`
export const questionnaire = (projectId, questionnaireId) => `${questionnaires(projectId)}/${questionnaireId}`
export const editQuestionnaire = (projectId, questionnaireId) => `${questionnaire(projectId, questionnaireId)}/edit`
export const channels = '/channels'

export const showOrEditSurvey = (s) => {
  if (s.state === 'not_ready' || s.state === 'ready') {
    return editSurvey(s.projectId, s.id)
  } else {
    return survey(s.projectId, s.id)
  }
}
