import React, { Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../actions/surveys'
import * as projectActions from '../actions/project'
import { createSurvey } from '../api'
import AddButton from '../components/AddButton'
import Card from '../components/Card'
import EmptyPage from '../components/EmptyPage'
import SurveyLink from '../components/SurveyLink'
import * as channelsActions from '../actions/channels'
import * as respondentActions from '../actions/respondents'
import RespondentsChart from '../components/RespondentsChart'
import UntitledIfEmpty from '../components/UntitledIfEmpty'
import * as RespondentsChartCount from '../components/RespondentsChartCount'
import * as routes from '../routes'

class SurveyIndex extends Component {
  static propTypes = {
    dispatch: React.PropTypes.func,
    router: React.PropTypes.object,
    projectId: React.PropTypes.number.isRequired,
    surveys: React.PropTypes.object,
    respondentsStats: React.PropTypes.object.isRequired
  }

  componentDidMount() {
    const { dispatch, projectId } = this.props

    // Fetch project for title
    dispatch(projectActions.fetchProject(projectId))

    dispatch(actions.fetchSurveys(projectId))
    .then(
      function x(value) {
        for (const surveyId in value) {
          dispatch(respondentActions.fetchRespondentsStats(projectId, surveyId))
        }
      }
    )
    dispatch(channelsActions.fetchChannels())
  }

  newSurvey() {
    const { dispatch, projectId, router } = this.props
    createSurvey(projectId).then(response => {
      dispatch(actions.setSurvey(response))
      router.push(routes.editSurvey(projectId, response.result))
    })
  }

  render() {
    const { surveys, respondentsStats } = this.props

    return (
      <div>
        <AddButton text='Add survey' onClick={() => this.newSurvey()} />
        { (Object.keys(surveys).length === 0) ?
          <EmptyPage icon='assignment_turned_in' title='You have no surveys on this project' onClick={(e) => this.newSurvey(e)} />
        :
          <div className='row'>
            { Object.keys(surveys).map((surveyId) =>
              <SurveyCard survey={surveys[surveyId]} completedByDate={respondentsStats[surveyId] ? respondentsStats[surveyId] : {}} key={surveyId} />
            )}
          </div>
        }
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: parseInt(ownProps.params.projectId),
  surveys: state.surveys,
  channels: state.channels,
  respondentsStats: state.respondentsStats
})

export default withRouter(connect(mapStateToProps)(SurveyIndex))

const SurveyCard = ({ survey, completedByDate }) => {
  let cumulativeCount = []
  let reached = 0

  if (survey && completedByDate.completedByDate) {
    const data = completedByDate.completedByDate.respondentsByDate
    const target = completedByDate.completedByDate.targetValue
    cumulativeCount = RespondentsChartCount.cumulativeCount(data, target)
    if (survey.state === 'running' || survey.state === 'completed') {
      reached = RespondentsChartCount.respondentsReachedPercentage(data, target)
    }
  }

  let icon = 'mode_edit'
  let color = 'black-text'
  let text = 'Editing'
  switch (survey.state) {
    case 'running':
      icon = 'play_arrow'
      color = 'green-text'
      text = 'Running'
      break
    case 'ready':
      icon = 'play_circle_outline'
      color = 'black-text'
      text = 'Ready to launch'
      break
    case 'completed':
      icon = 'done'
      color = 'black-text'
      text = 'Completed'
      break
  }
  return (
    <SurveyLink className='survey-card' survey={survey}>
      <div className='col s12 m6 l4'>
        <Card>
          <div className='card-content'>
            <div className='grey-text'>
              { reached + '% of target completed' }
            </div>
            <div className='card-chart'>
              <RespondentsChart completedByDate={cumulativeCount} />
            </div>
            <div className='card-status'>
              <span className='card-title'>
                <UntitledIfEmpty text={survey.name} />
              </span>
              <p className={color}>
                <i className='material-icons'>{icon}</i>
                { text }
              </p>
            </div>
          </div>
        </Card>
      </div>
    </SurveyLink>
  )
}

SurveyCard.propTypes = {
  completedByDate: React.PropTypes.array.isRequired,
  survey: React.PropTypes.object.isRequired
}
