import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import { EditableTitleLabel } from '../ui'
import * as questionnaireEditorActions from '../../actions/questionnaireEditor'

class QuestionnaireTitle extends Component {
  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    questionnaire: PropTypes.object
  }

  handleSubmit(newName) {
    const { dispatch } = this.props
    dispatch(questionnaireEditorActions.changeQuestionnaireName(newName))
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
