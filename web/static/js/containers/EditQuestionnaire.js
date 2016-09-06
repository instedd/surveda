import React, { Component, PropTypes } from 'react'
import { browserHistory } from 'react-router'
import { connect } from 'react-redux'
//import { v4 } from 'node-uuid'
import { Link, withRouter } from 'react-router'
import * as actions from '../actions/questionnaires'
import * as projectActions from '../actions/projects'
import { fetchQuestionnaire, fetchProject, updateQuestionnaire } from '../api'
import QuestionnaireForm from '../components/QuestionnaireForm'

class EditQuestionnaire extends Component {
  componentDidMount() {
    const { dispatch, questionnaireId, projectId } = this.props
    if(projectId && questionnaireId) {
      fetchQuestionnaire(projectId, questionnaireId).then(questionnaire => dispatch(actions.fetchQuestionnairesSuccess(questionnaire)))
      fetchProject(projectId).then(project => dispatch(projectActions.fetchProjectsSuccess(project)))
    }
  }

  componentDidUpdate() {
  }

  handleSubmit(dispatch) {
    const { projectId } = this.props
    return (questionnaire) => {
      updateQuestionnaire(projectId, questionnaire).then(questionnaire => dispatch(actions.updateQuestionnaire(questionnaire))).then(() => browserHistory.push(`/projects/${projectId}/questionnaires`))
    }
  }

  render(params) {
    let input
    const { children, questionnaire, project, projectId } = this.props
    return (<QuestionnaireForm onSubmit={this.handleSubmit(this.props.dispatch)} questionnaire={questionnaire} project={project} >{children}</QuestionnaireForm>)
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    projectId: ownProps.params.projectId,
    project: state.projects.projects[ownProps.params.projectId] || {},
    questionnaireId: ownProps.params.id,
    questionnaire: state.questionnaires[ownProps.params.id]
  }
}

export default withRouter(connect(mapStateToProps)(EditQuestionnaire))
