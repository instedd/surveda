import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import { EditableTitleLabel } from '../ui'
import * as questionnaireActions from '../../actions/questionnaire'

class QuestionnaireTitle extends Component {
  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    questionnaire: PropTypes.object
  }

  handleSubmit(newName) {
    const { dispatch } = this.props
    dispatch(questionnaireActions.changeName(newName))
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
