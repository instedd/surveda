import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import { EditableTitleLabel } from '../ui'
import * as questionnaireActions from '../../actions/questionnaire'

class QuestionnaireTitle extends Component {
  static propTypes = {
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
    const { questionnaire, readOnly } = this.props
    if (questionnaire == null) return null

    return <EditableTitleLabel title={questionnaire.name} onSubmit={(value) => { this.handleSubmit(value) }} entityName='questionnaire' readOnly={readOnly} />
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    questionnaire: state.questionnaire.data,
    readOnly: state.project && state.project.data ? state.project.data.readOnly : true
  }
}

export default withRouter(connect(mapStateToProps)(QuestionnaireTitle))
