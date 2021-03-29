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
    const { tabs, logout, user, project, surveyFolder, panelSurvey } = this.props
    const { projectId, surveyId, questionnaireId, folderId } = this.props.params

    let showProjectLink = true
    if (!project || (!surveyId && !questionnaireId && !folderId && !panelSurvey)) {
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
      <Header tabs={tabs} logout={logout} user={user} showProjectLink={showProjectLink} showQuestionnairesLink={!!questionnaireId} project={project || null} surveyFolder={surveyFolder} panelSurvey={panelSurvey} />
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
  panelSurvey: PropTypes.object
}

const mapStateToProps = (state, ownProps) => {
  const { params } = ownProps
  const folders = state.folder && state.folder.folders
  const survey = state.survey && state.survey.data
  const panelSurveyId = params.panelSurveyId && parseInt(params.panelSurveyId)

  let panelSurvey = null
  if (state.panelSurvey && state.panelSurvey.id == panelSurveyId) {
    panelSurvey = state.panelSurvey
  }

  let folder = null
  if (folders) {
    let folderId = null
    if (panelSurvey) folderId = panelSurvey.folderId
    else if (survey) folderId = survey.folderId
    if (folders[folderId]) folder = folders[folderId]
  }

  return {
    params: ownProps.params,
    project: state.project.data,
    surveyFolder: folder,
    panelSurvey: panelSurvey
  }
}

const mapDispatchToProps = (dispatch) => ({
  projectActions: bindActionCreators(projectActions, dispatch)
})

export default translate()(withRouter(connect(mapStateToProps, mapDispatchToProps)(HeaderContainer)))
