import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../../actions/survey'
import * as projectActions from '../../actions/project'
import * as channelsActions from '../../actions/channels'
import * as questionnairesActions from '../../actions/questionnaires'
import * as respondentsActions from '../../actions/respondents'
import SurveyForm from './SurveyForm'
import * as routes from '../../routes'

class SurveySettings extends Component {
  static propTypes = {
    dispatch: PropTypes.func,
    projectId: PropTypes.any.isRequired,
    surveyId: PropTypes.any.isRequired,
    router: PropTypes.object.isRequired,
    survey: PropTypes.object.isRequired,
    questionnaires: PropTypes.object,
    channels: PropTypes.object.isRequired,
    respondents: PropTypes.object
  }

  componentWillMount() {
    const { dispatch, projectId, surveyId } = this.props
    if (projectId && surveyId) {
      projectActions.fetchProject(projectId)
      dispatch(actions.fetchSurveyIfNeeded(projectId, surveyId))
      dispatch(projectActions.fetchProject(projectId))
      dispatch(channelsActions.fetchChannels())
      dispatch(questionnairesActions.fetchQuestionnaires(projectId))
      dispatch(respondentsActions.fetchRespondents(projectId, surveyId, 5, 1))
    }
  }

  render() {
    const { survey, projectId, questionnaires, dispatch, channels, respondents } = this.props

    if (Object.keys(survey).length == 0 || !respondents) {
      return <div>Loading...</div>
    }

    let questionnaireIds = survey.questionnaireIds || []
    let questionnaire = null
    if (questionnaireIds.length == 1) {
      questionnaire = questionnaires[questionnaireIds[0]]
    }

    return (
      <div className='white'>
        <SurveyForm survey={survey} respondents={respondents} projectId={projectId} questionnaires={questionnaires} channels={channels} dispatch={dispatch} questionnaire={questionnaire} readOnly />
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  surveyId: ownProps.params.surveyId,
  channels: state.channels.items || {},
  questionnaires: state.questionnaires.items || {},
  respondents: state.respondents,
  survey: state.survey.data || {}
})

export default withRouter(connect(mapStateToProps)(SurveySettings))
