import React, { Component } from 'react'
import { connect } from 'react-redux'
import * as questionnaireActions from '../actions/questionnaires'
import * as editorActions from '../actions/questionnaireEditor'
import * as projectActions from '../actions/projects'
import QuestionnaireForm from '../components/QuestionnaireForm'

class QuestionnaireEdit extends Component {
  componentWillMount () {
    const { dispatch, projectId, questionnaireId } = this.props

    if (projectId && questionnaireId) {
      dispatch(projectActions.fetchProject(projectId))

      dispatch(questionnaireActions.fetchQuestionnaire(projectId, questionnaireId))
        .then((questionnaire) => {
          // TODO: Fix this, or decide how to make it better
          var quest = questionnaire.response.entities.questionnaires[questionnaire.response.result]
          dispatch(editorActions.initializeEditor(quest))
        })
    }
  }

  render (params) {
    const { questionnaireEditor } = this.props

    return (
      <QuestionnaireForm questionnaireEditor={questionnaireEditor} />)
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  questionnaireId: ownProps.params.questionnaireId,
  questionnaireEditor: state.questionnaireEditor
})

export default connect(mapStateToProps)(QuestionnaireEdit)
