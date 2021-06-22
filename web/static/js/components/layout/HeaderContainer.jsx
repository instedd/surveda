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
    const { tabs, logout, user, project, folder, panelSurveyFromOccurrence } = this.props
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
      <Header tabs={tabs} logout={logout} user={user} showProjectLink={showProjectLink} showQuestionnairesLink={!!questionnaireId} project={project || null} folder={folder} panelSurvey={panelSurveyFromOccurrence} />
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
  folder: PropTypes.object,
  panelSurveyId: PropTypes.number,
  panelSurveyFromOccurrence: PropTypes.object
}

const getSurveyFromParams = (params, state) => {
  const surveyId = params.surveyId && parseInt(params.surveyId)
  const survey = state.survey && state.survey.data
  if (!survey || !surveyId || survey.id != surveyId) return null
  return survey
}

const getPanelSurveyFromOccurrence = (survey, state) => {
  if (!survey) return null
  const panelSurvey = state.panelSurveys.items && state.panelSurveys.items[survey.panelSurveyId]
  return panelSurvey || null
}

const getPanelSurveyFromParams = (params, state) => {
  const panelSurveyId = params.panelSurveyId && parseInt(params.panelSurveyId)
  if (!panelSurveyId) return null
  const panelSurvey = state.panelSurvey && state.panelSurvey.data
  if (!panelSurvey) return null
  if (panelSurvey.id == panelSurveyId) {
    return panelSurvey
  } else {
    return null
  }
}

const getFolderFromSurveyOrPanelSurvey = (surveyOrPanelSurvey, state) => {
  const folderId = surveyOrPanelSurvey ? surveyOrPanelSurvey.folderId : null
  const folder = state.folder && state.folder.folders && state.folder.folders[folderId]
  return folder || null
}

const mapStateToProps = (state, ownProps) => {
  /**
   * These are the survey related breadcrum cases:
    1. Project
    2. Project -> Survey : <Project>
    3. Project -> Panel Survey : <Project>
    4. Project -> Panel Survey -> Occurrence : <Project | PanelSurvey>
    5. Project -> Folder : <Project>
    6. Project -> Folder -> Survey : <Project | Folder>
    7. Project -> Folder -> Panel Survey : <Project | Folder>
    8. Project -> Folder -> Panel Survey -> Occurrence : <Project | Folder | PanelSurvey>
  */
  const { params } = ownProps
  const survey = getSurveyFromParams(params, state)
  const panelSurvey = getPanelSurveyFromParams(params, state)
  const panelSurveyFromOccurrence = getPanelSurveyFromOccurrence(survey, state)
  // First evaluate the panel survey from occurrence (case 8)
  // If the survey is evaluated before (case 6), the folder is missing for the case 8.
  const surveyOrPanelSurvey = panelSurveyFromOccurrence || panelSurvey || survey
  const folder = getFolderFromSurveyOrPanelSurvey(surveyOrPanelSurvey, state)
  return {
    project: state.project.data,
    panelSurveyFromOccurrence: panelSurveyFromOccurrence,
    folder
  }
}

const mapDispatchToProps = (dispatch) => ({
  projectActions: bindActionCreators(projectActions, dispatch)
})

export default translate()(withRouter(connect(mapStateToProps, mapDispatchToProps)(HeaderContainer)))
