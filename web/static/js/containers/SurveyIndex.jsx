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

class SurveyIndex extends Component {
  componentDidMount() {
    const { dispatch, projectId } = this.props
    dispatch(actions.fetchSurveys(projectId))
    .then(
      function x(value){
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
          <div className="row">
            { Object.keys(surveys).map((surveyId) =>
              <SurveyCard survey={surveys[surveyId]} completedByDate={respondentsStats[surveyId] ? respondentsStats[surveyId] : {}} key={surveyId}/>
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

const SurveyCard = ({ survey, completedByDate }) => {

  /* Begining Auxiliar functions */
  const cumulativeCountFor = function(d, completedByDate) {
    const dateMilliseconds = Date.parse(d)
    return completedByDate.reduce((pre, cur) => Date.parse(cur.date) <= dateMilliseconds ? pre + cur.count : pre, 0)
  }

  const cumulativeCount = function(completedByDate, targetValue) {
    const cumulativeCount = []
    for (let i = 0; i < completedByDate.length; i++) {
      let d = completedByDate[i].date
      let current = {}
      current['date'] = d
      current['count'] = cumulativeCountFor(d, completedByDate) / targetValue * 100
      cumulativeCount.push(current)
    }
    return cumulativeCount
  }

  const respondentsReached = function(completedByDate, targetValue) {
    const reached = completedByDate.length === 0 ? 0 : cumulativeCountFor(completedByDate[completedByDate.length - 1].date, completedByDate)
    return reached/targetValue
  }
  /* End Auxiliar functions */

  let acum = []
  let target = 1
  let reached = 0

  if(survey && completedByDate.completedByDate){
    const data = completedByDate.completedByDate.respondentsByDate
    const target = completedByDate.completedByDate.targetValue
    acum = cumulativeCount(data, target)
    if(survey.state === 'running' || survey.state === 'completed'){
      reached = respondentsReached(data, target)
    }
  }

  let icon = 'mode_edit'
  let color = "black-text"
  let text = 'Editing'
  switch (survey.state) {
    case 'running':
      icon = 'play_arrow'
      color = 'green-text'
      text = 'Running'
      break;
    case 'ready':
      icon = 'play_circle_outline'
      color = "black-text"
      text = 'Ready to launch'
      break;
    case 'completed':
      icon = 'done'
      color = "black-text"
      text = 'Completed'
      break;
  }

  return(
    <SurveyLink className="black-text" survey={ survey }>
      <div className="col s12 m6 l4">
        <Card>
          <div className="card-content">
            <div>
              { reached + '% respondents reached'}
            </div>
            <div style={{padding: '30px'}}>
              <RespondentsChart completedByDate={acum} />
            </div>
            <span className="card-title">
              { survey.name }
            </span>
            <p className={ color }>
              <i className="material-icons">{icon}</i>
              { text }
            </p>
          </div>
        </Card>
      </div>
    </SurveyLink>
  )
}
