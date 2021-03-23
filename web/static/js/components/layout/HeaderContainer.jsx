import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import Header from './Header'
import * as projectActions from '../../actions/project'
import { translate } from 'react-i18next'

class HeaderContainer extends Component {
  componentDidMount() {
    const { projectId, surveyId, questionnaireId } = this.props.params

    if (projectId && (surveyId || questionnaireId)) {
      this.props.projectActions.fetchProject(projectId)
    }
  }

  render() {
    const { tabs, logout, user, project, surveyFolder, panelSurveyFolder } = this.props
    const { projectId, surveyId, questionnaireId, folderId, panelSurveyId } = this.props.params

    let showProjectLink = true
    if (!project || (!surveyId && !questionnaireId && !folderId && !panelSurveyId)) {
      showProjectLink = false
    }

    if (projectId && !project) {
      // If there's a projectId and there's no project loaded
      // (it's still being loaded) we don't want to reset the body
      // class that came from the server.
    } else {
      let className = (project && project.colourScheme == 'better_data_for_health') ? 'bdfh' : ''
      $('body').removeClass('bdfh')
      $('body').addClass(className)
    }

    return (
      <Header tabs={tabs} logout={logout} user={user} showProjectLink={showProjectLink} showQuestionnairesLink={!!questionnaireId} project={project || null} surveyFolder={surveyFolder} panelSurveyFolder={panelSurveyFolder} />
    )
  }
}

HeaderContainer.propTypes = {
  projectActions: PropTypes.object.isRequired,
  params: PropTypes.object,
  project: PropTypes.object,
  tabs: PropTypes.node,
  logout: PropTypes.func.isRequired,
  user: PropTypes.string.isRequired,
  surveyFolder: PropTypes.object,
  panelSurveyFolder: PropTypes.object
}

export const surveyFolder = (surveyId, surveys, folders, panelSurveyId) => {
  if (!surveys || !folders) return null
  let survey = null
  if (panelSurveyId) {
    survey = surveys[panelSurveyId]
  } else {
    survey = surveys[surveyId]
  }
  if (!survey) return null
  const folder = folders[survey.folderId]
  if (!folder) return null

  return folder
}

const panelSurveyFolder = (survey, surveys, t) => {
  if (!survey || !survey.isPanelSurvey || !surveys) return null
  const firstPanelSurvey = surveys[survey.panelSurveyOf]
  const latestPanelSurvey = Object.values(surveys).filter(s => s.latestPanelSurvey && s.panelSurveyOf == survey.panelSurveyOf)[0]
  if (!firstPanelSurvey || !latestPanelSurvey) {
    // This isn't an normally expected state, but it's present the first time a survey is marked as repeatable.
    // We don't throw an error here because of this corner case.
    return null
  }
  // All the panel survey occurences are linked by the first occurrence via their `panelSurveyOf` property.
  // But the latest occurrence is the current (or at least the more recent) so its name is used to represent the panel survey as a folder.
  return {
    name: latestPanelSurvey.name,
    id: firstPanelSurvey.id,
    projectId: firstPanelSurvey.projectId
  }
}

const mapStateToProps = (state, ownProps) => {
  const { params, t } = ownProps
  const folders = state.folder && state.folder.folders
  const survey = state.survey && state.survey.data
  const surveyId = survey && survey.id
  const panelSurveyId = params.panelSurveyId && parseInt(params.panelSurveyId)
  const surveys = state.surveys.items

  return {
    params: ownProps.params,
    project: state.project.data,
    surveyFolder: (params.panelSurveyId || params.surveyId) && surveyFolder(surveyId, surveys, folders, panelSurveyId),
    panelSurveyFolder: params.surveyId && panelSurveyFolder(survey, surveys, t)
  }
}

const mapDispatchToProps = (dispatch) => ({
  projectActions: bindActionCreators(projectActions, dispatch)
})

export default translate()(withRouter(connect(mapStateToProps, mapDispatchToProps)(HeaderContainer)))
