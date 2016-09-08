import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../actions/surveys'
import * as projectActions from '../actions/projects'
import SurveyForm from '../components/SurveyForm'

class EditSurvey extends Component {
  componentDidMount() {
    const { dispatch, projectId, surveyId } = this.props
    if (projectId && surveyId) {
      dispatch(actions.fetchSurvey(projectId, surveyId))
      dispatch(projectActions.fetchProject(projectId))
    }
  }

  render(params) {
    const { children, survey, project } = this.props
    return (<SurveyForm survey={survey} project={project} >{children}</SurveyForm>)
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  project: state.projects[ownProps.params.projectId] || {},
  surveyId: ownProps.params.id,
  survey: state.surveys[ownProps.params.id] || {}
})

export default withRouter(connect(mapStateToProps)(EditSurvey))
