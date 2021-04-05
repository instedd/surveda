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
    const { tabs, logout, user, project, surveyFolder, panelSurveyId, panelSurvey } = this.props
    const { projectId, surveyId, questionnaireId, folderId } = this.props.params

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
  panelSurveyId: PropTypes.number,
  panelSurvey: PropTypes.object
}

const folder = (params, state) => {
  const { surveyId, panelSurveyId } = params
  let folderId = null
  if (state.survey.data && state.survey.data.id == surveyId) {
    folderId = state.survey.data.folderId
  } else if (state.panelSurvey.data && state.panelSurvey.data.id == panelSurveyId) {
    folderId = state.panelSurvey.data.folderId
  }
  const folder = state.folder && state.folder.folders && state.folder.folders[folderId]
  return folder || null
}

const panelSurvey = (surveyId, state) => {
  if (surveyId && state.survey && state.survey.data && state.survey.data.id == surveyId) {
    const survey = state.survey.data
    if (state.panelSurveys.items && state.panelSurveys.items[survey.panelSurveyOf]) {
      return state.panelSurveys.items[survey.panelSurveyOf]
    }
  }
  return null
}

const mapStateToProps = (state, ownProps) => {
  const { params } = ownProps
  const panelSurveyId = params.panelSurveyId && parseInt(params.panelSurveyId)
  const surveyId = params.surveyId && parseInt(params.surveyId)
  return {
    project: state.project.data,
    panelSurveyId,
    surveyFolder: folder(params, state),
    panelSurvey: panelSurvey(surveyId, state)
  }
}

const mapDispatchToProps = (dispatch) => ({
  projectActions: bindActionCreators(projectActions, dispatch)
})

export default translate()(withRouter(connect(mapStateToProps, mapDispatchToProps)(HeaderContainer)))
