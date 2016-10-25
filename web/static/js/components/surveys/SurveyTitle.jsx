import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import { EditableTitleLabel } from '../ui'
import merge from 'lodash/merge'
import * as surveyActions from '../../actions/survey'
import * as surveysActions from '../../actions/surveys'
import { updateSurvey } from '../../api'

class ProjectTitle extends Component {
  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    projectId: PropTypes.string.isRequired,
    surveyId: PropTypes.string.isRequired,
    survey: PropTypes.object
  }

  componentWillMount() {
    const { dispatch, projectId, surveyId } = this.props
    dispatch(surveyActions.fetch(projectId, surveyId))
  }

  handleSubmit(newName) {
    const { dispatch, survey } = this.props
    if (survey.name === newName) return
    const newSurvey = merge({}, survey, {name: newName})

    updateSurvey(newSurvey.projectId, newSurvey)
      .then(response => dispatch(surveyActions.receive(response.entities.surveys[response.result])))
      .catch((e) => dispatch(surveysActions.receiveSurveysError(e)))
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

export default withRouter(connect(mapStateToProps)(ProjectTitle))
