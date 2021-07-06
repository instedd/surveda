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

const getPanelSurveyFromOccurrence = (survey, state) => {
  if (!survey) return null
  const panelSurvey = state.panelSurveys.items && state.panelSurveys.items[survey.panelSurveyId]
  return panelSurvey || null
}

const getSurveyFromParams = (params, state) => getEntityFromParams(params, state, 'survey')
const getPanelSurveyFromParams = (params, state) => getEntityFromParams(params, state, 'panelSurvey')

const getEntityFromParams = (params, state, entityName) => {
  const entityId = params[`${entityName}Id`] && parseInt(params[`${entityName}Id`])
  const entity = state[entityName] && state[entityName].data
  if (!entity || !entityId || entity.id != entityId) return null
  return entity
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
  const surveyFromParams = getSurveyFromParams(params, state)
  const panelSurveyFromParams = getPanelSurveyFromParams(params, state)
  const panelSurveyFromOccurrence = getPanelSurveyFromOccurrence(surveyFromParams, state)

  // Here the order of the factors does alter the product.
  // Depending on the case, we need to take the folder from the panel survey taken from params,
  // from the survey taken from params, or from the panel survey taken from its occurrence.
  // For example evaluating (surveyFromParams || panelSurveyFromOccurrence) would work well but
  // just for some cases. It would work for getting the folder of a regular survey, but it
  // wouldn't work for getting the folder of an occurrence of a panel survey.
  const surveyOrPanelSurvey = panelSurveyFromOccurrence || panelSurveyFromParams || surveyFromParams

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
