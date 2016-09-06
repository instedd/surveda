import React, { Component, PropTypes } from 'react'
import { browserHistory } from 'react-router'
import { connect } from 'react-redux'
import { Link, withRouter } from 'react-router'
import * as actions from '../actions/questionnaires'
import { createQuestionnaire } from '../api'
import QuestionnaireForm from '../components/QuestionnaireForm'

class CreateQuestionnaire extends Component {
  handleSubmit(dispatch) {
    return (questionnaire) => {
      const { projectId } = this.props
      createQuestionnaire(projectId, questionnaire)
        .then(questionnaire => dispatch(actions.createQuestionnaire(questionnaire)))
        .then(() => browserHistory.push(`/projects/${projectId}/questionnaires`))
        // .catch((e) => dispatch(actions.fetchProjectsError(e)))
    }
  }

  render(params) {
    let input
    const { project, questionnaire } = this.props
    return (
      <QuestionnaireForm onSubmit={this.handleSubmit(this.props.dispatch)} project={project} questionnaire={questionnaire} />
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    projectId: ownProps.params.projectId,
    project: state.projects.projects[ownProps.params.projectId] || {},
    questionnaire: state.questionnaires[ownProps.params.id] || {},
  }
}

export default withRouter(connect(mapStateToProps)(CreateQuestionnaire))
