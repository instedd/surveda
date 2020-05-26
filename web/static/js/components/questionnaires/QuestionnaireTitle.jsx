import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import {EditableDescriptionLabel, EditableTitleLabel} from '../ui'
import QuestionnaireMenu from './QuestionnaireMenu'
import * as questionnaireActions from '../../actions/questionnaire'
import withQuestionnaire from './withQuestionnaire'
import { translate } from 'react-i18next'

class QuestionnaireTitle extends Component {
  static propTypes = {
    t: PropTypes.func,
    dispatch: PropTypes.func.isRequired,
    questionnaire: PropTypes.object,
    readOnly: PropTypes.bool,
    noMenu: PropTypes.bool
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
    const { questionnaire, readOnly, noMenu, t } = this.props

    return (
      <div className='title-container'>
        <EditableTitleLabel title={questionnaire.name} onSubmit={(value) => { this.handleSubmit(value) }} emptyText={t('Untitled questionnaire')} readOnly={readOnly} more={noMenu ? '' : <QuestionnaireMenu />} />
        <EditableDescriptionLabel description={questionnaire.description} emptyText={readOnly ? '' : t('Add description')} onSubmit={(value) => { this.handleSubmitDescription(value) }} readOnly={readOnly} />
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  readOnly: typeof ownProps.readOnly === 'boolean'
  ? ownProps.readOnly
  : (
    state.project && state.project.data
    ? state.project.data.readOnly
    : true
  )
})

export default translate()(connect(mapStateToProps)(withQuestionnaire(QuestionnaireTitle)))
