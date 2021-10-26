import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import Header from './Header'
import * as projectActions from '../../actions/project'
import { translate } from 'react-i18next'

class HeaderContainer extends Component {
  static propTypes = {
    dispatch: PropTypes.func,
    params: PropTypes.object,
    project: PropTypes.object,
    tabs: PropTypes.node,
    logout: PropTypes.func.isRequired,
    user: PropTypes.string.isRequired,
    folder: PropTypes.object,
    panelSurveyId: PropTypes.number,
    panelSurvey: PropTypes.object
  }

  componentDidMount() {
    const { projectId, surveyId, questionnaireId } = this.props.params
    const { dispatch, project } = this.props

    if (!project && projectId && (surveyId || questionnaireId)) {
      dispatch(projectActions.fetchProject(projectId))
    }
  }

  render() {
    const { tabs, logout, user, project, folder, panelSurvey } = this.props
    const { projectId, surveyId, questionnaireId, folderId, panelSurveyId } = this.props.params
    const showProjectLink = project && (surveyId || questionnaireId || folderId || panelSurveyId)

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
      <Header tabs={tabs} logout={logout} user={user} showProjectLink={!!showProjectLink} showQuestionnairesLink={!!questionnaireId} project={project || null} folder={folder} panelSurvey={panelSurvey} />
    )
  }
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

  const surveyId = params['surveyId']
  const panelSurveyId = params['panelSurveyId']
  let panelSurvey, folder

  // Here the order of the factors does alter the product.
  // Depending on the case, we need to take the folder from the panel survey taken from params,
  // from the survey taken from params, or from the panel survey taken from its occurrence.
  // For example evaluating (surveyFromParams || panelSurveyFromOccurrence) would work well but
  // just for some cases. It would work for getting the folder of a regular survey, but it
  // wouldn't work for getting the folder of an occurrence of a panel survey.
  if (surveyId) {
    const survey = state.survey.data && state.survey.data.id == parseInt(surveyId) && state.survey.data
    panelSurvey = survey ? survey.panelSurvey : null
    folder = panelSurvey ? panelSurvey.folder : (survey ? survey.folder : null)
  } else if (panelSurveyId) {
    panelSurvey = state.panelSurvey.data && state.panelSurvey.data.id == parseInt(panelSurveyId) && state.panelSurvey.data
    folder = panelSurvey ? panelSurvey.folder : null
    panelSurvey = null
  }

  return {
    project: state.project.data,
    folder,
    panelSurvey
  }
}

export default translate()(withRouter(connect(mapStateToProps)(HeaderContainer)))
