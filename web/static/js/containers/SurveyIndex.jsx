import React, { Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../actions/surveys'
import { createSurvey } from '../api'
import AddButton from '../components/AddButton'
import Card from '../components/Card'
import EmptyPage from '../components/EmptyPage'
import SurveyLink from '../components/SurveyLink'
import * as channelsActions from '../actions/channels'
import * as respondentActions from '../actions/respondents'
import RespondentsChart from '../components/RespondentsChart'
import * as RespondentsChartCount from '../components/RespondentsChartCount'

class SurveyIndex extends Component {
  componentDidMount() {
    const { dispatch, projectId } = this.props
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
      router.push(`/projects/${projectId}/surveys/${response.result}/edit`)
    })
  }

  render() {
    const { surveys, router, channels, respondentsStats } = this.props

    const title = parseInt(Object.keys(surveys).length, 10) + ' Surveys'

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
  projectId: ownProps.params.projectId,
  surveys: state.surveys,
  channels: state.channels,
  respondentsStats: state.respondentsStats
})

export default withRouter(connect(mapStateToProps)(SurveyIndex))

const respondentsReached = function(completedByDate, targetValue) {
  const reached = completedByDate.length === 0 ? 0 : RespondentsChartCount.cumulativeCountFor(completedByDate[completedByDate.length - 1].date, completedByDate)
  return Math.round(reached * 100 / targetValue)
}

const SurveyCard = ({ survey, completedByDate }) => {
  let cumulativeCount = []
  let reached = 0

  if (survey && completedByDate.completedByDate) {
    const data = completedByDate.completedByDate.respondentsByDate
    const target = completedByDate.completedByDate.targetValue
    cumulativeCount = RespondentsChartCount.cumulativeCount(data, target)
    if (survey.state === 'running' || survey.state === 'completed') {
      reached = respondentsReached(data, target)
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

  let surveyNameComponent
  if (!survey.name || survey.name.trim() === '') {
    surveyNameComponent = <i>Untitled</i>
  } else {
    surveyNameComponent = survey.name
  }

  return (
    <SurveyLink className='survey-card' survey={survey}>
      <div className='col s12 m6 l4'>
        <Card>
          <div className='card-content'>
            <div className='grey-text'>
              { reached + '% respondents reached'}
            </div>
            <div className='card-chart'>
              <RespondentsChart completedByDate={cumulativeCount} />
            </div>
            <div className='card-status'>
              <span className='card-title'>
                { surveyNameComponent }
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
