import React, { Component, PureComponent, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter, Link } from 'react-router'
import values from 'lodash/values'
import * as actions from '../../actions/surveys'
import * as surveyActions from '../../actions/survey'
import * as projectActions from '../../actions/project'
import { AddButton, Card, EmptyPage, UntitledIfEmpty } from '../ui'
import * as channelsActions from '../../actions/channels'
import * as respondentActions from '../../actions/respondents'
import RespondentsChart from '../respondents/RespondentsChart'
import SurveyStatus from './SurveyStatus'
import * as RespondentsChartCount from '../respondents/RespondentsChartCount'
import * as routes from '../../routes'

class SurveyIndex extends Component {
  static propTypes = {
    dispatch: PropTypes.func,
    router: PropTypes.object,
    projectId: PropTypes.any.isRequired,
    surveys: PropTypes.array,
    respondentsStats: PropTypes.object.isRequired
  }

  componentDidMount() {
    const { dispatch, projectId } = this.props

    // Fetch project for title
    dispatch(projectActions.fetchProject(projectId))

    dispatch(actions.fetchSurveys(projectId))
    .then(value => {
      for (const surveyId in value) {
        dispatch(respondentActions.fetchRespondentsStats(projectId, surveyId))
      }
    })
    dispatch(channelsActions.fetchChannels())
  }

  newSurvey() {
    const { dispatch, projectId, router } = this.props
    dispatch(surveyActions.createSurvey(projectId)).then(survey =>
      router.push(routes.surveyEdit(projectId, survey))
    )
  }

  render() {
    const { surveys, respondentsStats } = this.props

    if (!surveys) {
      return (
        <div>Loading surveys...</div>
      )
    }

    return (
      <div>
        <AddButton text='Add survey' onClick={() => this.newSurvey()} />
        { surveys.length == 0
        ? <EmptyPage icon='assignment_turned_in' title='You have no surveys on this project' onClick={(e) => this.newSurvey(e)} />
        : <div className='row'>
          { surveys.map(survey => (
            <SurveyCard survey={survey} completedByDate={respondentsStats[survey.id]} key={survey.id} />
          )) }
        </div>
        }
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  // Right now we show all surveys: they are not paginated nor sorted
  let surveys = state.surveys.items
  if (surveys) {
    surveys = values(surveys)
  }
  return {
    projectId: ownProps.params.projectId,
    surveys,
    channels: state.channels,
    respondentsStats: state.respondentsStats
  }
}

export default withRouter(connect(mapStateToProps)(SurveyIndex))

class SurveyCard extends PureComponent {
  static propTypes = {
    completedByDate: React.PropTypes.object.isRequired,
    survey: React.PropTypes.object.isRequired
  }

  render() {
    const { survey, completedByDate } = this.props
    let cumulativeCount = []
    let reached = 0

    if (survey && completedByDate && completedByDate.completedByDate) {
      const data = completedByDate.completedByDate.respondentsByDate
      const target = completedByDate.completedByDate.cutoff || completedByDate.completedByDate.totalRespondents
      cumulativeCount = RespondentsChartCount.cumulativeCount(data, target)
      if (survey.state == 'running' || survey.state == 'completed') {
        reached = RespondentsChartCount.respondentsReachedPercentage(data, target)
      }
    }

    return (
      <Link className='survey-card' to={routes.showOrEditSurvey(survey)}>
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
                <span className='card-title truncate' title={survey.name}>
                  <UntitledIfEmpty text={survey.name} />
                </span>
                <SurveyStatus survey={survey} />
              </div>
            </div>
          </Card>
        </div>
      </Link>
    )
  }
}
