// @flow
import React, { Component } from 'react'
import { connect } from 'react-redux'
import {EditableDescriptionLabel, EditableTitleLabel} from '../ui'
import QuestionnaireMenu from './QuestionnaireMenu'
import * as questionnaireActions from '../../actions/questionnaire'
import { translate } from 'react-i18next'
import { withRouter } from 'react-router'

type Props = {
  t: Function,
  dispatch: Function,
  questionnaire: Object,
  readOnly: boolean,
  projectId: number,
  questionnaireId: number
}

class QuestionnaireTitle extends Component<Props> {
  componentWillMount() {
    const { dispatch, projectId, questionnaireId } = this.props
    if (projectId && questionnaireId) {
      dispatch(questionnaireActions.fetchQuestionnaireIfNeeded(projectId, questionnaireId))
    }
  }

  handleSubmit(newName) {
    const { dispatch, questionnaire } = this.props
    if (questionnaire.name == newName) return

    dispatch(questionnaireActions.changeName(newName))
  }

  handleSubmitDescription(newDescription) {
    const { dispatch, questionnaire } = this.props
    if (questionnaire.description == newDescription) return

    dispatch(questionnaireActions.changeDescription(newDescription))
  }

  render() {
    const { questionnaire, readOnly, t } = this.props
    if (questionnaire) {
      return (
        <div className='title-container'>
          <EditableTitleLabel title={questionnaire.name} onSubmit={(value) => { this.handleSubmit(value) }} emptyText={t('Untitled questionnaire')} readOnly={readOnly} more={<QuestionnaireMenu />} />
          <EditableDescriptionLabel description={questionnaire.description} emptyText={readOnly ? '' : t('Add description')} onSubmit={(value) => { this.handleSubmitDescription(value) }} readOnly={readOnly} />
        </div>
      )
    } else {
      return null
    }
  }
}

const mapStateToProps = (state, ownProps) => {
  const { readOnly, params } = ownProps
  const { projectId, questionnaireId, mode } = params
  return {
    projectId: parseInt(projectId),
    questionnaireId: parseInt(questionnaireId),
    mode,
    questionnaire: state.questionnaire.data,
    readOnly: typeof readOnly === 'boolean'
    ? readOnly
    : (
      state.project && state.project.data
      ? state.project.data.readOnly
      : true
    )
  }
}

export default translate()(withRouter(connect(mapStateToProps)(QuestionnaireTitle)))
