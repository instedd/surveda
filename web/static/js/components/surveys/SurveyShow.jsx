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
        <span className='type'>{type} Mode</span>
        <div>
          <i className='material-icons'>{this.iconForMode(mode)}</i>
          <span className='mode-label name'>{this.labelForMode(mode)}</span>
        </div>
      </div>
    )
  }

  render() {
    const { survey, respondentsStats, completedByDate, target, totalRespondents, questionnaire } = this.props
    const cumulativeCount = RespondentsChartCount.cumulativeCount(completedByDate, target)

    if (!survey || !completedByDate || !questionnaire) {
      return <p>Loading...</p>
    }

    let primaryMode = this.modeFor('Primary', survey.mode[0])
    let fallbackMode = null
    if (survey.mode.length > 1) {
      fallbackMode = this.modeFor('Fallback', survey.mode[1])
    }

    let modes = <div className='survey-modes col s12 m4'>
      {primaryMode}
      {fallbackMode}
    </div>

    return (
      <div>
        <div className='row'>
          <div className='col s12 m8'>
            <h4>
              {questionnaire.name}
            </h4>
            <SurveyStatus survey={survey} />
          </div>
        </div>
        <div className='row'>
          <div className='col s12 m8'>
            <div className='card'>
              <div className='card-table-title'>
                Dispositions
              </div>
              <div className='card-table'>
                <table>
                  <thead>
                    <tr>
                      <th>Status</th>
                      <th>Quantity</th>
                      <th>Percent</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td>Pending</td>
                      <td>{ respondentsStats.pending.count }</td>
                      <td>{ respondentsStats.pending.percent }%</td>
                    </tr>
                    <tr>
                      <td>Active</td>
                      <td>{ respondentsStats.active.count }</td>
                      <td>{ respondentsStats.active.percent }%</td>
                    </tr>
                    <tr>
                      <td>Completed</td>
                      <td>{ respondentsStats.completed.count }</td>
                      <td>{ respondentsStats.completed.percent }%</td>
                    </tr>
                    <tr>
                      <td>Stalled</td>
                      <td>{ respondentsStats.stalled.count }</td>
                      <td>{ respondentsStats.stalled.percent }%</td>
                    </tr>
                    <tr>
                      <td>Failed</td>
                      <td>{ respondentsStats.failed.count }</td>
                      <td>{ respondentsStats.failed.percent }%</td>
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
          {modes}
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
    questionnaire: state.questionnaire.data,
    respondentsStats: respondentsStats,
    completedByDate: completedRespondentsByDate,
    target: target,
    totalRespondents: totalRespondents
  })
}

export default withRouter(connect(mapStateToProps)(SurveyShow))
