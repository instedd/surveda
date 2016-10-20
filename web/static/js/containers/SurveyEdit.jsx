import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as surveyActions from '../actions/surveyEdit'
import * as actions from '../actions/surveys'
import * as projectActions from '../actions/project'
import * as channelsActions from '../actions/channels'
import * as questionnairesActions from '../actions/questionnaires'
import * as respondentsActions from '../actions/respondents'
import SurveyForm from '../components/SurveyForm'
import { Tooltip } from '../components/Tooltip'
import { launchSurvey, updateSurvey } from '../api'
import * as routes from '../routes'

class SurveyEdit extends Component {
  static propTypes = {
    dispatch: PropTypes.func,
    projectId: PropTypes.number.isRequired,
    surveyId: PropTypes.string.isRequired,
    router: PropTypes.object.isRequired,
    survey: PropTypes.object.isRequired,
    questionnaires: PropTypes.object.isRequired,
    channels: PropTypes.object.isRequired,
    project: PropTypes.object.isRequired,
    respondents: PropTypes.object.isRequired
  }

  componentWillMount() {
    const { dispatch, projectId, surveyId, router } = this.props
    dispatch(surveyActions.initializeEditor({}))
    if (projectId && surveyId) {
      projectActions.fetchProject(projectId)
      dispatch(actions.fetchSurvey(projectId, surveyId))
        .then((survey) => {
          dispatch(surveyActions.initializeEditor(survey))
          if (survey.state === 'running') {
            router.replace(routes.survey(survey.projectId, survey.id))
          }
        })
      dispatch(projectActions.fetchProject(projectId))
      dispatch(channelsActions.fetchChannels())
      dispatch(questionnairesActions.fetchQuestionnaires(projectId))
      dispatch(respondentsActions.fetchRespondents(projectId, surveyId))
    }
  }

  launchSurvey() {
    const { dispatch, projectId, surveyId, router } = this.props
    launchSurvey(projectId, surveyId)
        .then(survey => dispatch(actions.receiveSurveys(survey)))
        .then(() => router.push(routes.survey(projectId, surveyId)))
  }

  onSubmit(e) {
    const { dispatch, survey } = this.props
    updateSurvey(survey.projectId, survey)
      .then(updatedSurvey => dispatch(actions.setSurvey(updatedSurvey)))
      .catch((e) => dispatch(actions.receiveSurveysError(e)))
  }

  render() {
    const { survey, projectId, questionnaires, dispatch, channels, respondents } = this.props
    if (Object.keys(survey).length === 0) {
      return <div>Loading...</div>
    }
    return (
      <div className='white'>
        { survey.state === 'ready'
          ? <Tooltip text='Launch survey'>
            <a className='btn-floating btn-large waves-effect waves-light green right mtop' onClick={() => this.launchSurvey()}>
              <i className='material-icons'>play_arrow</i>
            </a>
          </Tooltip>
          : ''
        }
        <SurveyForm survey={survey} respondents={respondents} projectId={projectId} questionnaires={questionnaires} channels={channels} onSubmit={(e) => this.onSubmit(e)} dispatch={dispatch} />
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: parseInt(ownProps.params.projectId),
  project: state.projects[ownProps.params.projectId] || {},
  surveyId: ownProps.params.surveyId,
  channels: state.channels,
  questionnaires: state.questionnaires,
  respondents: state.respondents,
  survey: state.surveyEdit || {}
})

export default withRouter(connect(mapStateToProps)(SurveyEdit))
