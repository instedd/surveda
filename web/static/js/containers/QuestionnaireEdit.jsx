import React, { Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as questionnaireActions from '../actions/questionnaires'
import * as editorActions from '../actions/questionnaireEditor'
import * as projectActions from '../actions/projects'
import { updateQuestionnaire } from '../api'
import QuestionnaireForm from '../components/QuestionnaireForm'

class QuestionnaireEdit extends Component {
  componentDidMount() {
    const { dispatch, projectId, questionnaireId } = this.props

    console.log(dispatch)

    if (projectId && questionnaireId) {
      dispatch(projectActions.fetchProject(projectId))

      dispatch(questionnaireActions.fetchQuestionnaire(projectId, questionnaireId))
        .then((questionnaire) => {
          dispatch(editorActions.initializeEditor(questionnaire))
        })
    }
  }

  handleSubmit() {
    const { projectId, router, dispatch } = this.props
    return (questionnaire) => {
      updateQuestionnaire(projectId, questionnaire)
        .then(questionnaire => dispatch(questionnaireActions.updateQuestionnaire(questionnaire)))
        .then(() => router.push(`/projects/${projectId}/questionnaires`))
    }
  }

  render(params) {
    const { questionnaireEditor } = this.props

    return (
      <QuestionnaireForm
        onSubmit={this.handleSubmit()}
        questionnaireEditor={questionnaireEditor} />)
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  questionnaireId: ownProps.params.questionnaireId,
  questionnaireEditor: state.questionnaireEditor
})

export default withRouter(connect(mapStateToProps)(QuestionnaireEdit))
