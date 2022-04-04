import React, { Component, PropTypes } from "react"
import { connect } from "react-redux"
import { withRouter } from "react-router"
import Header from "./Header"
import * as projectActions from "../../actions/project"
import { translate } from "react-i18next"

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
    panelSurvey: PropTypes.object,
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
      let className = project && project.colourScheme == "better_data_for_health" ? "bdfh" : ""
      $("body").removeClass("bdfh")
      $("body").addClass(className)
    }

    return (
      <Header
        tabs={tabs}
        logout={logout}
        user={user}
        showProjectLink={!!showProjectLink}
        showQuestionnairesLink={!!questionnaireId}
        project={project || null}
        folder={folder}
        panelSurvey={panelSurvey}
      />
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  /**
   * These are the survey related breadcrum cases:
    1. Project
    2. Project -> Survey : <Project>
    3. Project -> Panel Survey : <Project>
    4. Project -> Panel Survey -> Wave : <Project | PanelSurvey>
    5. Project -> Folder : <Project>
    6. Project -> Folder -> Survey : <Project | Folder>
    7. Project -> Folder -> Panel Survey : <Project | Folder>
    8. Project -> Folder -> Panel Survey -> Wave : <Project | Folder | PanelSurvey>
  */
  const { params } = ownProps

  const surveyId = params["surveyId"]
  const panelSurveyId = params["panelSurveyId"]
  let panelSurvey, folder

  // We build the breadcrumb in reverse order, and never display the current
  // level (the currently opened folder, panel survey or survey), only the
  // parents:
  if (surveyId) {
    // 1. survey (no parent)
    // 2. survey -> folder
    // 3. survey -> panel survey
    // 4. survey -> panel survey -> folder
    const currentSurvey =
      state.survey.data && state.survey.data.id == parseInt(surveyId) && state.survey.data
    panelSurvey = currentSurvey ? currentSurvey.panelSurvey : null
    folder = panelSurvey ? panelSurvey.folder : currentSurvey ? currentSurvey.folder : null
  } else if (panelSurveyId) {
    // 5. panel survey (no parent)
    // 6. panel survey -> folder
    const currentPanelSurvey =
      state.panelSurvey.data &&
      state.panelSurvey.data.id == parseInt(panelSurveyId) &&
      state.panelSurvey.data
    folder = currentPanelSurvey ? currentPanelSurvey.folder : null
  }

  return {
    project: state.project.data,
    folder,
    panelSurvey,
  }
}

export default translate()(withRouter(connect(mapStateToProps)(HeaderContainer)))
