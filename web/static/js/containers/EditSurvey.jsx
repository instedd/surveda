import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../actions/surveys'
import * as projectActions from '../actions/projects'
import SurveyForm from '../components/SurveyForm'
import { Tooltip } from '../components/Tooltip'
import { launchSurvey } from '../api'

class EditSurvey extends Component {
  componentDidMount() {
    const { dispatch, projectId, surveyId } = this.props
    if (projectId && surveyId) {
      dispatch(actions.fetchSurvey(projectId, surveyId))
      dispatch(projectActions.fetchProject(projectId))
    }
  }

  launchSurvey() {
    const { dispatch, projectId, surveyId, router } = this.props
    launchSurvey(projectId, surveyId)
        .then(survey => dispatch(actions.receiveSurveys(survey)))
        .then(() => router.push(`/projects/${projectId}/surveys/${surveyId}`))
  }

  render(params) {
    const { children, survey, project } = this.props
    return (
      <div>
        <Tooltip text="Launch survey">
          <a className="btn-floating btn-large waves-effect waves-light green right mtop" onClick={() => this.launchSurvey()}>
            <i className="material-icons">play_arrow</i>
          </a>
        </Tooltip>
        <SurveyForm survey={survey} project={project} >{children}</SurveyForm>)
      </div>
      )
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  project: state.projects[ownProps.params.projectId] || {},
  surveyId: ownProps.params.surveyId,
  survey: state.surveys[ownProps.params.surveyId] || {}
})

export default withRouter(connect(mapStateToProps)(EditSurvey))
