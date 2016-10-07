import React, { Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as editorActions from '../actions/questionnaireEditor'
import QuestionnaireForm from '../components/QuestionnaireForm'

class QuestionnaireNew extends Component {
  componentDidMount () {
    const { projectId, dispatch } = this.props
    dispatch(editorActions.newQuestionnaire(projectId))
  }

  render () {
    const { questionnaireEditor } = this.props
    return <QuestionnaireForm questionnaireEditor={questionnaireEditor} />
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  project: state.projects[ownProps.params.projectId] || {},
  questionnaireEditor: state.questionnaireEditor
})

export default withRouter(connect(mapStateToProps)(QuestionnaireNew))
