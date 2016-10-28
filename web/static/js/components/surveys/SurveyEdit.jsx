import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../../actions/survey'
import * as surveyActions from '../../actions/surveys'
import * as projectActions from '../../actions/project'
import * as channelsActions from '../../actions/channels'
import * as questionnairesActions from '../../actions/questionnaires'
import * as respondentsActions from '../../actions/respondents'
import SurveyForm from './SurveyForm'
import { Tooltip } from '../ui'
import { launchSurvey, updateSurvey } from '../../api'
import * as routes from '../../routes'

class SurveyEdit extends Component {
  static propTypes = {
    dispatch: PropTypes.func,
    projectId: PropTypes.number.isRequired,
    surveyId: PropTypes.number.isRequired,
    router: PropTypes.object.isRequired,
    survey: PropTypes.object.isRequired,
    questionnaires: PropTypes.object,
    channels: PropTypes.object.isRequired,
    project: PropTypes.object.isRequired,
    respondents: PropTypes.object
  }

  componentWillMount() {
    const { dispatch, projectId, surveyId } = this.props
    if (projectId && surveyId) {
      projectActions.fetchProject(projectId)
      dispatch(actions.fetchSurveyIfNeeded(projectId, surveyId))
        .then((survey) => {
          if (survey && survey.state == 'running') {
            router.replace(routes.survey(survey.projectId, survey.id))
          }
        })
      dispatch(projectActions.fetchProject(projectId))
      dispatch(channelsActions.fetchChannels())
      dispatch(questionnairesActions.fetchQuestionnaires(projectId))
      dispatch(respondentsActions.fetchRespondents(projectId, surveyId, 5, 1))
    }
  }

  componentDidUpdate() {
    const { survey, router } = this.props
    if (survey && survey.state === 'running') {
      router.replace(routes.survey(survey.projectId, survey.id))
    }
  }

  launchSurvey() {
    const { dispatch, projectId, surveyId, router } = this.props
    launchSurvey(projectId, surveyId)
        .then(survey => dispatch(actions.receive(survey)))
        .then(() => router.push(routes.survey(projectId, surveyId)))
  }

  onSubmit(e) {
    const { dispatch, survey } = this.props
    updateSurvey(survey.projectId, survey)
      .then(response => dispatch(actions.setState(response.entities.surveys[response.result].state)))
      .catch((e) => dispatch(surveyActions.receiveSurveysError(e)))
  }

  render() {
    const { survey, projectId, questionnaires, dispatch, channels, respondents } = this.props

    if (Object.keys(survey).length == 0 || !respondents) {
      return <div>Loading...</div>
    }

    return (
      <div className='white'>
        { survey.state == 'ready'
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
  projectId: ownProps.params.projectId,
  project: state.projects[ownProps.params.projectId] || {},
  surveyId: ownProps.params.surveyId,
  channels: state.channels,
  questionnaires: state.questionnaires.items || {},
  respondents: state.respondents.items,
  survey: state.survey.data || {}
})

export default withRouter(connect(mapStateToProps)(SurveyEdit))
