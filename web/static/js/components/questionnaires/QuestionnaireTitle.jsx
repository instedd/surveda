import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import { EditableTitleLabel } from '../ui'
import merge from 'lodash/merge'
import * as questionnaireActions from '../../actions/questionnaire'
import { updateQuestionnaire } from '../../api'

class QuestionnaireTitle extends Component {
  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    questionnaire: PropTypes.object
  }

  handleSubmit(newName) {
    const { dispatch, questionnaire } = this.props
    if (questionnaire.name == newName) return
    const newQuestionnaire = merge({}, questionnaire, {name: newName})

    dispatch(questionnaireActions.updateQuestionnaire(newQuestionnaire)) // Optimistic update
    updateQuestionnaire(questionnaire.projectId, newQuestionnaire)
      .then(response => dispatch(questionnaireActions.updateQuestionnaire(response.entities.questionnaires[response.result])))
  }

  render() {
    const { questionnaire } = this.props
    if (questionnaire == null) return null

    return <EditableTitleLabel title={questionnaire.name} onSubmit={(value) => { this.handleSubmit(value) }} />
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    questionnaire: state.questionnaire.data
  }
}

export default withRouter(connect(mapStateToProps)(QuestionnaireTitle))
