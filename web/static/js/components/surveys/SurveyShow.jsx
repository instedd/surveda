import React, { Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../../actions/survey'
import * as respondentActions from '../../actions/respondents'
import RespondentsChart from '../respondents/RespondentsChart'
import { UntitledIfEmpty } from '../ui'
import * as RespondentsChartCount from '../respondents/RespondentsChartCount'
import * as routes from '../../routes'

class SurveyShow extends Component {
  static propTypes = {
    dispatch: React.PropTypes.func,
    router: React.PropTypes.object,
    projectId: React.PropTypes.number.isRequired,
    surveyId: React.PropTypes.string.isRequired,
    survey: React.PropTypes.object,
    respondentsStats: React.PropTypes.object,
    completedByDate: React.PropTypes.array,
    target: React.PropTypes.number,
    totalRespondents: React.PropTypes.number
  }

  componentWillMount() {
    const { dispatch, projectId, surveyId } = this.props
    dispatch(actions.fetchSurveyIfNeeded(projectId, surveyId))
    dispatch(respondentActions.fetchRespondentsStats(projectId, surveyId))
  }

  componentDidUpdate() {
    const { survey, router } = this.props
    if (survey && survey.state == 'not_ready') {
      router.replace(routes.editSurvey(survey.projectId, survey.id))
    }
  }

  respondentsFraction(completedByDate, targetValue) {
    const reached = completedByDate.length == 0 ? 0 : RespondentsChartCount.cumulativeCountFor(completedByDate[completedByDate.length - 1].date, completedByDate)
    return reached + '/' + targetValue
  }

  render() {
    const { survey, respondentsStats, completedByDate, target, totalRespondents } = this.props
    const cumulativeCount = RespondentsChartCount.cumulativeCount(completedByDate, target)

    if (!survey || !completedByDate) {
      return <p>Loading...</p>
    }

    return (
      <div>
        <div className='row'>
          <div className='col s12 m8'>
            <div className='card'>
              <div className='card-table-title'>
                <UntitledIfEmpty text={survey.name} />
              </div>
              <div className='card-table'>
                <table>
                  <thead>
                    <tr>
                      <th>Pending</th>
                      <th>Active</th>
                      <th>Completed</th>
                      <th>Failed</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td>{ respondentsStats.pending }</td>
                      <td>{ respondentsStats.active }</td>
                      <td>{ respondentsStats.completed }</td>
                      <td>{ respondentsStats.failed }</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
          <div>
            { RespondentsChartCount.respondentsReachedPercentage(completedByDate, target) + '% of target completed' }
          </div>
          <div className='col s12 m4'>
            <RespondentsChart completedByDate={cumulativeCount} />
            <div>
              Respondents contacted
            </div>
            { this.respondentsFraction(completedByDate, totalRespondents) }
          </div>
        </div>
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  const respondentsStatsRoot = state.respondentsStats[ownProps.params.surveyId]

  let respondentsStats = {}
  let completedRespondentsByDate = []
  // Default values
  let target = 1
  let totalRespondents = 1

  if (respondentsStatsRoot) {
    respondentsStats = respondentsStatsRoot.respondentsByState
    completedRespondentsByDate = respondentsStatsRoot.completedByDate.respondentsByDate
    target = respondentsStatsRoot.completedByDate.cutoff || respondentsStatsRoot.completedByDate.totalRespondents
    totalRespondents = respondentsStatsRoot.completedByDate.totalRespondents
  }

  return ({
    projectId: ownProps.params.projectId,
    project: state.project.data,
    surveyId: ownProps.params.surveyId,
    survey: state.survey.data,
    respondentsStats: respondentsStats,
    completedByDate: completedRespondentsByDate,
    target: target,
    totalRespondents: totalRespondents
  })
}

export default withRouter(connect(mapStateToProps)(SurveyShow))
