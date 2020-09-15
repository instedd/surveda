import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import {EditableDescriptionLabel, EditableTitleLabel} from '../ui'
import QuestionnaireMenu from './QuestionnaireMenu'
import * as questionnaireActions from '../../actions/questionnaire'
import withQuestionnaire from './withQuestionnaire'
import { translate } from 'react-i18next'
import { isProjectReadOnly } from '../../reducers/project'
import { isQuestionnaireReadOnly } from '../../reducers/questionnaire'

class QuestionnaireTitle extends Component {
  static propTypes = {
    t: PropTypes.func,
    dispatch: PropTypes.func.isRequired,
    questionnaire: PropTypes.object,
    readOnly: PropTypes.bool,
    hideMenu: PropTypes.bool
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
    const { questionnaire, readOnly, hideMenu, t } = this.props

    return (
      <div className='title-container'>
        <EditableTitleLabel title={questionnaire.name} onSubmit={(value) => { this.handleSubmit(value) }} emptyText={t('Untitled questionnaire')} readOnly={readOnly} more={hideMenu ? '' : <QuestionnaireMenu readOnly={readOnly} />} />
        <EditableDescriptionLabel description={questionnaire.description} emptyText={readOnly ? '' : t('Add description')} onSubmit={(value) => { this.handleSubmitDescription(value) }} readOnly={readOnly} />
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  const { readOnly } = ownProps
  if (typeof readOnly === 'boolean') {
    // Explicitly set by the component user
    return { readOnly }
  } else {
    return { readOnly: isProjectReadOnly(state) || isQuestionnaireReadOnly(state) }
  }
}

export default translate()(connect(mapStateToProps)(withQuestionnaire(QuestionnaireTitle)))
