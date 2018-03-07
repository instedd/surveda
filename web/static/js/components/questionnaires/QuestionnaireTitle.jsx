import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { EditableTitleLabel } from '../ui'
import QuestionnaireMenu from './QuestionnaireMenu'
import * as questionnaireActions from '../../actions/questionnaire'
import withQuestionnaire from './withQuestionnaire'
import { translate } from 'react-i18next'

class QuestionnaireTitle extends Component {
  static propTypes = {
    t: PropTypes.func,
    dispatch: PropTypes.func.isRequired,
    questionnaire: PropTypes.object,
    readOnly: PropTypes.bool
  }

  handleSubmit(newName) {
    const { dispatch, questionnaire } = this.props
    if (questionnaire.name == newName) return

    dispatch(questionnaireActions.changeName(newName))
  }

  render() {
    const { questionnaire, readOnly, t } = this.props

    return <EditableTitleLabel title={questionnaire.name} onSubmit={(value) => { this.handleSubmit(value) }} emptyText={t('Untitled questionnaire')} readOnly={readOnly} more={<QuestionnaireMenu />} />
  }
}

const mapStateToProps = (state, ownProps) => ({
  readOnly: state.project && state.project.data ? state.project.data.readOnly : true
})

export default translate()(connect(mapStateToProps)(withQuestionnaire(QuestionnaireTitle)))
