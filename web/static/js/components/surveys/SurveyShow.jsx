import React, { Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../../actions/survey'
import * as questionnaireActions from '../../actions/questionnaire'
import * as respondentActions from '../../actions/respondents'
import RespondentsChart from '../respondents/RespondentsChart'
import SurveyStatus from './SurveyStatus'
import * as RespondentsChartCount from '../respondents/RespondentsChartCount'
import * as routes from '../../routes'

class SurveyShow extends Component {
  static propTypes = {
    dispatch: React.PropTypes.func,
    router: React.PropTypes.object,
    projectId: React.PropTypes.string.isRequired,
    surveyId: React.PropTypes.string.isRequired,
    survey: React.PropTypes.object,
    questionnaire: React.PropTypes.object,
    respondentsStats: React.PropTypes.object,
    respondentsQuotasStats: React.PropTypes.array,
    completedByDate: React.PropTypes.array,
    target: React.PropTypes.number,
    totalRespondents: React.PropTypes.number
  }

  componentWillMount() {
    const { dispatch, projectId, surveyId } = this.props
    dispatch(actions.fetchSurveyIfNeeded(projectId, surveyId)).then(survey =>
      dispatch(questionnaireActions.fetchQuestionnaireIfNeeded(projectId, survey.questionnaireId))
    )
    dispatch(respondentActions.fetchRespondentsStats(projectId, surveyId))
    dispatch(respondentActions.fetchRespondentsQuotasStats(projectId, surveyId))
  }

  componentDidUpdate() {
    const { survey, router } = this.props
    if (survey && survey.state == 'not_ready') {
      router.replace(routes.surveyEdit(survey.projectId, survey.id))
    }
  }

  respondentsFraction(completedByDate, targetValue) {
    const reached = completedByDate.length == 0 ? 0 : RespondentsChartCount.cumulativeCountFor(completedByDate[completedByDate.length - 1].date, completedByDate)
    return reached + '/' + targetValue
  }

  iconForMode(mode) {
    let icon = null
    if (mode == 'sms') {
      icon = 'sms'
    } else {
      icon = 'phone'
    }

    return icon
  }

  labelForMode(mode) {
    let label = null
    if (mode == 'sms') {
      label = 'SMS'
    } else {
      label = 'IVR'
    }

    return label
  }

  modeFor(type, mode) {
    return (
      <div className='mode'>
        <label className='grey-text'>{type} Mode</label>
        <div>
          <i className='material-icons'>{this.iconForMode(mode)}</i>
          <span className='mode-label name'>{this.labelForMode(mode)}</span>
        </div>
      </div>
    )
  }

  render() {
    const { survey, respondentsStats, respondentsQuotasStats, completedByDate, target, totalRespondents, questionnaire } = this.props
    const cumulativeCount = RespondentsChartCount.cumulativeCount(completedByDate, target)

    if (!survey || !completedByDate || !questionnaire || !respondentsQuotasStats || !respondentsStats) {
      return <p>Loading...</p>
    }

    let primaryMode = this.modeFor('Primary', survey.mode[0])
    let fallbackMode = null
    if (survey.mode.length > 1) {
      fallbackMode = this.modeFor('Fallback', survey.mode[1])
    }

    let modes = <div className='survey-modes'>
      {primaryMode}
      {fallbackMode}
    </div>

    let table
    if (respondentsQuotasStats.length > 0) {
      table = this.quotasForAnswers(respondentsQuotasStats)
    } else {
      table = this.dispositions(respondentsStats)
    }

    return (
      <div className='row'>
        <div className='col s12 m8'>
            <h4>
              {questionnaire.name}
            </h4>
            <SurveyStatus survey={survey} />
            {table}
        </div>
        <div className='col s12 m4'>
          <div className='row survey-chart'>
            <div className='col s12'>
              <label className='grey-text'>
                { RespondentsChartCount.respondentsReachedPercentage(completedByDate, target) + '% of target completed' }
              </label>
            </div>
          </div>
          <div className='row respondent-chart'>
            <div className='col s12'>
              <RespondentsChart completedByDate={cumulativeCount} />
            </div>
          </div>
          <div className='row'>
            <div className='col s12'>
              <label className='grey-text'>
                Respondents contacted
              </label>
              <div>
                { this.respondentsFraction(completedByDate, totalRespondents) }
              </div>
            </div>
          </div>
          <div className='row'>
            <div className='col s12'>
              {modes}
            </div>
          </div>
        </div>
      </div>
    )
  }

  dispositions(respondentsStats) {
    return (
    <div className='card'>
      <div className='card-table-title'>
        Dispositions
      </div>
      <div className='card-table'>
        <table>
          <thead>
            <tr>
              <th>Status</th>
              <th className='right-align'>Quantity</th>
              <th className='right-align'>Percent</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Pending</td>
              <td className='right-align'>{ respondentsStats.pending.count }</td>
              <td className='right-align'>{ Math.round(respondentsStats.pending.percent) }%</td>
            </tr>
            <tr>
              <td>Active</td>
              <td className='right-align'>{ respondentsStats.active.count }</td>
              <td className='right-align'>{ Math.round(respondentsStats.active.percent) }%</td>
            </tr>
            <tr>
              <td>Completed</td>
              <td className='right-align'>{ respondentsStats.completed.count }</td>
              <td className='right-align'>{ Math.round(respondentsStats.completed.percent) }%</td>
            </tr>
            <tr>
              <td>Stalled</td>
              <td className='right-align'>{ respondentsStats.stalled.count }</td>
              <td className='right-align'>{ Math.round(respondentsStats.stalled.percent) }%</td>
            </tr>
            <tr>
              <td>Failed</td>
              <td className='right-align'>{ respondentsStats.failed.count }</td>
              <td className='right-align'>{ Math.round(respondentsStats.failed.percent) }%</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    )
  }

  quotasForAnswers(stats) {
    return (
    <div className='card'>
      <div className='card-table-title'>
        {stats.length} quotas for answers
      </div>
      <div className='card-table'>
        <table>
          <thead>
            <tr>
              <th>Quota</th>
              <th className='right-align'>Target</th>
              <th className='right-align'>Percent</th>
              <th className='right-align'>Full</th>
              <th className='right-align'>Partials</th>
            </tr>
          </thead>
          <tbody>
            { stats.map((stat, index) => {
              let conditions = []
              for(let key in stat.condition) {
                conditions.push([`${key}: ${stat.condition[key]}`])
              }
              return (
                <tr key={index}>
                  <td>
                    { conditions.map((condition, index2) => (
                      <span key={index2}>
                        {condition}
                        <br/>
                      </span>
                    )) }
                  </td>
                  <td className='right-align'>{stat.quota}</td>
                  <td className='right-align'>{Math.round(stat.count * 100.0 / stat.quota)}%</td>
                  <td className='right-align'>{stat.full}</td>
                  <td className='right-align'>{stat.partials}</td>
                </tr>
              )
            }) }
          </tbody>
        </table>
      </div>
    </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  const respondentsStatsRoot = state.respondentsStats[ownProps.params.surveyId]
  const respondentsQuotasStats = state.respondentsQuotasStats.data

  let respondentsStats = null
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
    questionnaire: state.questionnaire.data,
    respondentsStats: respondentsStats,
    respondentsQuotasStats: respondentsQuotasStats,
    completedByDate: completedRespondentsByDate,
    target: target,
    totalRespondents: totalRespondents
  })
}

export default withRouter(connect(mapStateToProps)(SurveyShow))
