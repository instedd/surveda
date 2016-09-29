import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../actions/questionnaires'
import { createQuestionnaire } from '../api'
import QuestionnaireForm from '../components/QuestionnaireForm'

class QuestionnaireNew extends Component {
  handleSubmit() {
    return (questionnaire) => {
      const { projectId, router, dispatch } = this.props
      createQuestionnaire(projectId, questionnaire)
        .then(questionnaire => dispatch(actions.createQuestionnaire(questionnaire)))
        .then(() => router.push(`/projects/${projectId}/questionnaires`))
        // .catch((e) => dispatch(actions.receiveProjectsError(e)))
    }
  }

  render(params) {
    const { project, questionnaire, currentStepId } = this.props
    return <QuestionnaireForm onSubmit={this.handleSubmit()} project={project} questionnaire={questionnaire} currentStepId={currentStepId} />
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  project: state.projects[ownProps.params.projectId] || {},
  questionnaire: {},
  currentStepId: state.questionnaireEditor.currentStepId,
})

export default withRouter(connect(mapStateToProps)(QuestionnaireNew))
