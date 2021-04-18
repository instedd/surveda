import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import { EditableTitleLabel, EditableDescriptionLabel } from '../ui'
import * as surveyActions from '../../actions/survey'
import { translate } from 'react-i18next'
import { isProjectReadOnly } from '../../reducers/project'
import * as panelSurveysAction from '../../actions/panelSurveys'

class SurveyTitle extends Component {
  static propTypes = {
    t: PropTypes.func,
    dispatch: PropTypes.func.isRequired,
    projectId: PropTypes.any.isRequired,
    surveyId: PropTypes.any.isRequired,
    survey: PropTypes.object,
    readOnly: PropTypes.bool
  }

  handleSubmitTitle(newName) {
    const { dispatch, survey, projectId } = this.props
    if (survey.name == newName) return

    dispatch(surveyActions.changeName(newName))

    // Refresh the panel surveys for breadcrumb. So when the panel survey name is changed,
    // the breadcrumb is updated.
    // TODO: this is a workaround and should be removed in the future.
    // It's needed because there is no panel survey model yet, so the panel survey name is being
    // taken from the last occurrence of the panel survey.
    if (survey.isPanelSurvey) dispatch(panelSurveysAction.fetchPanelSurveys(projectId))
  }

  handleSubmitDescription(newDescription) {
    const { dispatch, survey } = this.props
    if (survey.description == newDescription) return

    dispatch(surveyActions.changeDescription(newDescription))
  }

  render() {
    const { survey, readOnly, t } = this.props
    if (survey == null) return null

    return (
      <div className='title-container'>
        <EditableTitleLabel title={survey.name} emptyText={t('Untitled survey')} onSubmit={(value) => { this.handleSubmitTitle(value) }} readOnly={readOnly} />
        <EditableDescriptionLabel description={survey.description} emptyText={t('Add description')} onSubmit={(value) => { this.handleSubmitDescription(value) }} readOnly={readOnly} />
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    projectId: ownProps.params.projectId,
    surveyId: ownProps.params.surveyId,
    survey: state.survey.data,
    readOnly: isProjectReadOnly(state)
  }
}

export default translate()(withRouter(connect(mapStateToProps)(SurveyTitle)))
