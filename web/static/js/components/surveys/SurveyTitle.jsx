import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import { EditableTitleLabel } from '../ui'
import * as surveyActions from '../../actions/survey'
import { translate } from 'react-i18next'

class SurveyTitle extends Component {
  static propTypes = {
    t: PropTypes.func,
    dispatch: PropTypes.func.isRequired,
    projectId: PropTypes.any.isRequired,
    surveyId: PropTypes.any.isRequired,
    survey: PropTypes.object,
    readOnly: PropTypes.bool
  }

  handleSubmit(newName) {
    const { dispatch, survey } = this.props
    if (survey.name == newName) return

    dispatch(surveyActions.changeName(newName))
  }

  render() {
    const { survey, readOnly, t } = this.props
    if (survey == null) return null

    return <EditableTitleLabel title={survey.name} emptyText={t('Untitled survey')} onSubmit={(value) => { this.handleSubmit(value) }} readOnly={readOnly} />
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    projectId: ownProps.params.projectId,
    surveyId: ownProps.params.surveyId,
    survey: state.survey.data,
    readOnly: state.project && state.project.data ? state.project.data.readOnly : true
  }
}

export default translate()(withRouter(connect(mapStateToProps)(SurveyTitle)))
