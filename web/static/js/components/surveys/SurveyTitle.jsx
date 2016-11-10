import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import { EditableTitleLabel } from '../ui'
import * as surveyActions from '../../actions/survey'

class SurveyTitle extends Component {
  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    projectId: PropTypes.any.isRequired,
    surveyId: PropTypes.any.isRequired,
    survey: PropTypes.object
  }

  componentWillMount() {
    const { dispatch, projectId, surveyId } = this.props
    dispatch(surveyActions.fetchSurveyIfNeeded(projectId, surveyId))
  }

  handleSubmit(newName) {
    const { dispatch, survey } = this.props
    if (survey.name == newName) return

    dispatch(surveyActions.changeName(newName))
  }

  render() {
    const { survey } = this.props
    if (survey == null) return null

    return <EditableTitleLabel title={survey.name} onSubmit={(value) => { this.handleSubmit(value) }} />
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    projectId: ownProps.params.projectId,
    surveyId: ownProps.params.surveyId,
    survey: state.survey.data
  }
}

export default withRouter(connect(mapStateToProps)(SurveyTitle))
