import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../../actions/survey'
import * as projectActions from '../../actions/project'
import * as channelsActions from '../../actions/channels'
import * as questionnairesActions from '../../actions/questionnaires'
import * as respondentGroupsActions from '../../actions/respondentGroups'
import SurveyForm from './SurveyForm'
import { Tooltip } from '../ui'
import { launchSurvey } from '../../api'
import * as routes from '../../routes'

class SurveyEdit extends Component {
  static propTypes = {
    dispatch: PropTypes.func,
    projectId: PropTypes.any.isRequired,
    surveyId: PropTypes.any.isRequired,
    router: PropTypes.object.isRequired,
    survey: PropTypes.object.isRequired,
    questionnaires: PropTypes.object,
    channels: PropTypes.object,
    project: PropTypes.object,
    respondentGroups: PropTypes.object,
    invalidRespondents: PropTypes.object
  }

  componentWillMount() {
    const { dispatch, projectId, surveyId } = this.props
    if (projectId && surveyId) {
      projectActions.fetchProject(projectId)
      dispatch(actions.fetchSurveyIfNeeded(projectId, surveyId))
      dispatch(projectActions.fetchProject(projectId))
      dispatch(channelsActions.fetchChannels())
      dispatch(questionnairesActions.fetchQuestionnaires(projectId))
      dispatch(respondentGroupsActions.fetchRespondentGroups(projectId, surveyId))
    }
  }

  componentDidUpdate() {
    const { survey, router } = this.props
    if (survey && survey.state && survey.state != 'not_ready' && survey.state != 'ready') {
      router.replace(routes.survey(survey.projectId, survey.id))
    }
  }

  launchSurvey() {
    const { projectId, surveyId, router } = this.props
    launchSurvey(projectId, surveyId)
      .then(() => router.push(routes.survey(projectId, surveyId)))
  }

  render() {
    const { survey, projectId, project, questionnaires, dispatch, channels, respondentGroups, invalidRespondents } = this.props

    if (Object.keys(survey).length == 0 || !respondentGroups) {
      return <div>Loading...</div>
    }

    const readOnly = !project || project.readOnly

    let questionnaireIds = survey.questionnaireIds || []
    let questionnaire = null
    if (questionnaireIds.length == 1) {
      questionnaire = questionnaires[questionnaireIds[0]]
    }

    let launchComponent = null
    if (survey.state == 'ready' && !readOnly) {
      launchComponent = (
        <Tooltip text='Launch survey'>
          <a className='btn-floating btn-large waves-effect waves-light green right mtop' onClick={() => this.launchSurvey()}>
            <i className='material-icons'>play_arrow</i>
          </a>
        </Tooltip>
      )
    }

    return (
      <div className='white'>
        {launchComponent}
        <SurveyForm survey={survey} respondentGroups={respondentGroups} invalidRespondents={invalidRespondents} projectId={projectId} questionnaires={questionnaires} channels={channels} dispatch={dispatch} questionnaire={questionnaire} readOnly={readOnly} />
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  project: state.project.data,
  surveyId: ownProps.params.surveyId,
  channels: state.channels.items,
  questionnaires: state.questionnaires.items || {},
  respondentGroups: state.respondentGroups.items || {},
  invalidRespondents: state.respondentGroups.invalidRespondents,
  survey: state.survey.data || {}
})

export default withRouter(connect(mapStateToProps)(SurveyEdit))
