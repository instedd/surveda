// @flow
import React, { Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../../actions/survey'
import * as respondentActions from '../../actions/respondents'
import SurveyStatus from './SurveyStatus'
import * as routes from '../../routes'
import { Tooltip, Modal } from '../ui'
import { stopSurvey } from '../../api'
import capitalize from 'lodash/capitalize'
import sum from 'lodash/sum'
import { modeLabel } from '../../questionnaire.mode'
import { referenceColorClasses, referenceColors } from '../../referenceColors'
import classNames from 'classnames/bind'
import { Stats, Forecasts } from '@instedd/surveda-d3-components'

// TODO Remove this dependency
import * as d3 from 'd3'

class SurveyShow extends Component {
  static propTypes = {
    dispatch: React.PropTypes.func,
    router: React.PropTypes.object,
    project: React.PropTypes.object,
    projectId: React.PropTypes.string.isRequired,
    surveyId: React.PropTypes.string.isRequired,
    survey: React.PropTypes.object,
    questionnaires: React.PropTypes.object,
    respondentsByDisposition: React.PropTypes.object,
    reference: React.PropTypes.array,
    completedByDate: React.PropTypes.object,
    contactedRespondents: React.PropTypes.number,
    totalRespondents: React.PropTypes.number,
    target: React.PropTypes.number,
    completionPercentage: React.PropTypes.number,
    cumulativePercentages: React.PropTypes.object
  }

  state: {
    responsive: boolean,
    contacted: boolean,
    uncontacted: boolean,
    stopUnderstood: boolean
  }

  constructor(props) {
    super(props)
    this.state = {
      responsive: false, contacted: false, uncontacted: false, stopUnderstood: false
    }
  }

  componentWillMount() {
    const { dispatch, projectId, surveyId } = this.props
    dispatch(actions.fetchSurveyIfNeeded(projectId, surveyId))
    dispatch(respondentActions.fetchRespondentsStats(projectId, surveyId))
  }

  componentDidUpdate() {
    const { survey, router } = this.props
    if (survey && survey.state == 'not_ready') {
      router.replace(routes.surveyEdit(survey.projectId, survey.id))
    }
  }

  stopSurvey() {
    this.setState({stopUnderstood: false})
    this.refs.stopModal.open()
  }

  toggleStopUnderstood() {
    this.setState((state) => ({ stopUnderstood: !state.stopUnderstood }))
  }

  stopCancel() {
    this.refs.stopModal.close()
  }

  confirmStopSurvey() {
    const { projectId, surveyId, router } = this.props
    this.refs.stopModal.close()
    stopSurvey(projectId, surveyId)
      .then(() => router.push(routes.surveyEdit(projectId, surveyId)))
  }

  iconForMode(mode: string) {
    let icon = null
    switch (mode) {
      case 'sms':
        icon = 'sms'
        break
      case 'ivr':
        icon = 'phone'
        break
      case 'mobileweb':
        icon = 'phonelink'
        break
      default:
        throw new Error(`Unhandled mode in iconForMode: ${mode}`)
    }
    return icon
  }

  letterForIndex(index) {
    return String.fromCodePoint(65 + index) // A, B, C, ...
  }

  modeFor(index: number, mode: string) {
    let type = (index == 0) ? 'Primary' : 'Fallback'
    return (
      <div className='mode' key={mode}>
        <label className='grey-text'>{type} Mode</label>
        <div>
          <i className='material-icons'>{this.iconForMode(mode)}</i>
          <span className='mode-label name'>{modeLabel(mode)}</span>
        </div>
      </div>
    )
  }

  modesForComparisons(modes: string[]) {
    return modes.length == 2
      ? `${modeLabel(modes[0])}, ${modeLabel(modes[1])} fallback`
      : modeLabel(modes[0])
  }

  titleFor(questionnaires) {
    let isComparison = Object.keys(questionnaires).length > 1
    let title = ''
    if (isComparison) {
      title = 'Questionnaire performance comparison'
    } else {
      let questionnaireId = Object.keys(questionnaires)[0]
      title = questionnaires[questionnaireId].name
    }

    return title
  }

  render() {
    const { questionnaires, survey, respondentsByDisposition, reference, contactedRespondents, cumulativePercentages, target, project } = this.props
    const { stopUnderstood } = this.state

    if (!survey || !cumulativePercentages || !questionnaires || !respondentsByDisposition || !reference) {
      return <p>Loading...</p>
    }

    const readOnly = !project || project.readOnly

    let stopComponent = null
    if (!readOnly && survey.state == 'running') {
      stopComponent = (
        <Tooltip text='Stop survey'>
          <a className='btn-floating btn-large waves-effect waves-light red right mtop' onClick={() => this.stopSurvey()}>
            <i className='material-icons'>stop</i>
          </a>
        </Tooltip>
      )
    }

    let title = this.titleFor(questionnaires)

    let stats = [
      {value: target, label: 'Target'},
      {value: respondentsByDisposition.responsive.detail.completed.count, label: 'Completes'},
      {value: respondentsByDisposition.responsive.detail.partial.count, label: 'Partials'},
      {value: contactedRespondents, label: 'Contacted Respondents'}
    ]

    let colors = referenceColors(reference.length)

    let forecastsReferences = reference.map((r, i) => {
      const name = r.name ? r.name : ''
      const modes = r.modes ? this.modesForComparisons(r.modes) : ''
      const separator = name && modes ? ' | ' : ''

      return {
        label: `${name}${separator}${modes}`,
        color: colors[i],
        id: r.id
      }
    })

    // let getValues = (start, today) => {
    //   const days = d3.timeDays(start, today, 1)
    //   var value = 0
    //   const values = days.map(time => {
    //     value += Math.round(Math.random() * 50)
    //     return {time, value}
    //   })
    //   return values
    // }

    // TODO: Make this a real forecast
    // let getForecast = (today, end, initial) => {
    //   const days = d3.timeDays(new Date(today.getTime() - 24 * 60 * 60 * 1000), end, 1)
    //   var value = initial
    //   const forecast = days.map(time => {
    //     var item = {time, value}
    //     value += Math.round(Math.random() * 50)
    //     return item
    //   })
    //   return forecast
    // }

    // const start = new Date()
    // const today = new Date(start.getTime() + Math.random() * 45 * 24 * 60 * 60 * 1000)
    // const end = new Date(today.getTime() + Math.round(Math.random() * 50 * 24 * 60 * 60 * 1000))

    const formatDate = date => {
      return new Date(Date.parse(date))
    }

    let forecasts = forecastsReferences.map(d => {
      // let values = getValues(start, today)
      // let initial = values.length ? values[values.length - 1].value : 0
      // let forecast = getForecast(today, end, initial)

      const values = (cumulativePercentages[d.id] || []).map(v => (
        { time: formatDate(v.date), value: Number(v.percent) }
      ))

      return {...d, values, forecast: []}
    })

    return (
      <div className='cockpit'>
        <div className='row'>
          {stopComponent}
          <Modal card ref='stopModal' id='stop_survey_modal'>
            <div className='modal-content'>
              <div className='card-title header'>
                <h5>Stop survey</h5>
                <p>This will finalize the survey execution</p>
              </div>
              <div className='card-content'>
                <div className='row'>
                  <div className='col s12'>
                    <p className='red-text alert-left-icon'>
                      <i className='material-icons'>warning</i>
                      Stopped surveys cannot be restarted
                    </p>
                  </div>
                </div>
                <div className='row'>
                  <div className='col s12'>
                    <p>
                      Once you stop the survey, all invitations will be halted immediately.
                    </p>
                    <p>
                      Respondents who are currently answering the survey will be cut off. Once
                      you stop, you cannot restart.
                    </p>
                  </div>
                </div>
                <div className='row'>
                  <div className='col s12'>
                    <input
                      id='stop_understood'
                      type='checkbox'
                      checked={stopUnderstood}
                      onChange={() => this.toggleStopUnderstood()}
                      className='filled-in' />
                    <label htmlFor='stop_understood'>Understood</label>
                  </div>
                </div>
              </div>
              <div className='card-action'>
                <a
                  className={classNames('btn-large red', { disabled: !stopUnderstood })}
                  onClick={() => this.confirmStopSurvey()}>
                  Stop
                </a>
                <a className='btn-flat grey-text' onClick={() => this.stopCancel()}>Cancel</a>
              </div>
            </div>
          </Modal>
          <h4>
            {title}
          </h4>
          <SurveyStatus survey={survey} />
          <div className='col s12'>
            <div className='card' style={{'width': '100%', padding: '60px 30px'}}>
              <div className='header'>
                <div className='title'>Percent of completes</div>
                {survey.countPartialResults
                  ? <div className='description'>Count partials as completed</div>
                  : ''
                }
              </div>

              <Stats data={stats} />
              <Forecasts data={forecasts} />
            </div>
          </div>
        </div>
        <div className='row'>
          <div className='col s12'>
            {this.dispositions(respondentsByDisposition, reference)}
          </div>
        </div>
      </div>
    )
  }

  // Round a number to two decimals, but only if the number has decimals
  round(num) {
    if (num == parseInt(num)) {
      return num
    } else {
      return num.toFixed(2)
    }
  }

  expandGroup(group) {
    let newState = {
      ...this.state
    }
    newState[group] = !this.state[group]
    this.setState(newState)
  }

  groupRows(group, groupStats, reference) {
    let details = groupStats.detail
    let detailsKeys = Object.keys(details)
    let referenceIds = Object.keys(reference)
    let colorClasses = referenceColorClasses(referenceIds.length)

    const groupStatsbyReference = (referenceIds, detailsKeys, colorClasses, details) => {
      if (referenceIds.length > 1) {
        return referenceIds.map((referenceId, i) => {
          const totals = detailsKeys.map((detail) => details[detail].byReference[referenceId] || 0)
          return <td key={referenceId} className={classNames('right-align', colorClasses[i])}>{sum(totals)}</td>
        })
      }
    }
    const groupRow =
      <tr key={group}>
        <td>{capitalize(group)}</td>
        {groupStatsbyReference(referenceIds, detailsKeys, colorClasses, details)}
        <td className='right-align'>{groupStats.count}</td>
        <td className='right-align'>{this.round(groupStats.percent)}%</td>
        <td className='expand-column'>
          <a className='link' onClick={e => this.expandGroup(group)}>
            <i className='material-icons right grey-text'>{this.state[group] ? 'expand_less' : 'expand_more'}</i>
          </a>
        </td>
      </tr>

    let rows = null
    if (this.state[group]) {
      rows = detailsKeys.map((detail) => {
        let individualStat = details[detail]

        let byReference = individualStat['byReference']
        let referenceColumns = null
        if (referenceIds.length > 1) {
          referenceColumns = referenceIds.map((referenceId, i) => {
            let value = null
            if (detail == 'registered') {
              value = '-'
            } else {
              value = byReference[referenceId] || 0
            }

            return <td key={referenceId} className={classNames('right-align', colorClasses[i])}>{value}</td>
          })
        }

        return (
          <tr className='detail-row' key={detail}>
            <td>{capitalize(detail)}</td>
            {referenceColumns}
            <td className='right-align'>{individualStat.count}</td>
            <td className='right-align'>{this.round(individualStat.percent)}%</td>
            <td className='expand-column' />
          </tr>
        )
      })
    }

    return [groupRow, rows]
  }

  dispositions(respondentsByDisposition, reference) {
    const dispositionsGroup = ['responsive', 'contacted', 'uncontacted']
    let referenceIds = Object.keys(reference)
    return (
      <div className='card overflow'>
        <div className='card-table-title'>
          Dispositions
        </div>
        <div className='card-table'>
          <table>
            <thead>
              <tr>
                <th>Status</th>
                {referenceIds.length > 1 ? referenceIds.map((referenceId) => (<th key={referenceId} className='right-align' />)) : []}
                <th className='right-align'>Quantity</th>
                <th className='right-align'>
                  Percent
                </th>
              </tr>
            </thead>
            <tbody>
              {
                dispositionsGroup.map(group => {
                  let groupStats = respondentsByDisposition[group]
                  return this.groupRows(group, groupStats, reference)
                })
              }
            </tbody>
          </table>
        </div>
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  const respondentsStatsRoot = state.respondentsStats[ownProps.params.surveyId]

  let respondentsByDisposition = null
  let cumulativePercentages = {}
  let contactedRespondents = 0
  let totalRespondents = 0
  let target = 0
  let completionPercentage = 0
  let reference = null

  if (respondentsStatsRoot) {
    respondentsByDisposition = respondentsStatsRoot.respondentsByDisposition
    cumulativePercentages = respondentsStatsRoot.cumulativePercentages
    contactedRespondents = respondentsStatsRoot.contactedRespondents
    totalRespondents = respondentsStatsRoot.totalRespondents
    target = respondentsStatsRoot.target
    completionPercentage = respondentsStatsRoot.completionPercentage
    reference = respondentsStatsRoot.reference
  }

  return ({
    projectId: ownProps.params.projectId,
    project: state.project.data,
    surveyId: ownProps.params.surveyId,
    survey: state.survey.data,
    questionnaires: !state.survey.data ? {} : state.survey.data.questionnaires,
    respondentsByDisposition: respondentsByDisposition,
    cumulativePercentages: cumulativePercentages,
    contactedRespondents: contactedRespondents,
    totalRespondents: totalRespondents,
    target: target,
    reference: reference,
    completionPercentage: completionPercentage
  })
}

export default withRouter(connect(mapStateToProps)(SurveyShow))
