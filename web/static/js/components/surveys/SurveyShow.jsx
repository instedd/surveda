// @flow
import React, { Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../../actions/survey'
import * as respondentActions from '../../actions/respondents'
import RespondentsChart from '../respondents/RespondentsChart'
import SurveyStatus from './SurveyStatus'
import * as routes from '../../routes'
import { Tooltip, ConfirmationModal, UntitledIfEmpty } from '../ui'
import { stopSurvey } from '../../api'
import capitalize from 'lodash/capitalize'
import sum from 'lodash/sum'
import reduce from 'lodash/reduce'
import { modeLabel } from '../../questionnaire.mode'
import { referenceBackgroundColorClasses, referenceColorClasses } from '../../referenceColors'
import classNames from 'classnames/bind'

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
    respondentsQuotasStats: React.PropTypes.object,
    respondentsStats: React.PropTypes.object,
    completedByDate: React.PropTypes.object,
    contactedRespondents: React.PropTypes.number,
    totalRespondents: React.PropTypes.number,
    completionPercentage: React.PropTypes.number,
    cumulativePercentages: React.PropTypes.object
  }

  state: {
    responsive: boolean,
    contacted: boolean,
    uncontacted: boolean
  }

  constructor(props) {
    super(props)
    this.state = {
      responsive: false, contacted: false, uncontacted: false
    }
  }

  componentWillMount() {
    const { dispatch, projectId, surveyId } = this.props
    dispatch(actions.fetchSurveyIfNeeded(projectId, surveyId))
    dispatch(respondentActions.fetchRespondentsStats(projectId, surveyId))
    dispatch(respondentActions.fetchRespondentsQuotasStats(projectId, surveyId))
  }

  componentDidUpdate() {
    const { survey, router } = this.props
    if (survey && survey.state == 'not_ready') {
      router.replace(routes.surveyEdit(survey.projectId, survey.id))
    }
  }

  stopSurvey() {
    const { projectId, surveyId, survey, router } = this.props
    const stopConfirmationModal = this.refs.stopConfirmationModal
    stopConfirmationModal.open({
      modalText: <span>
        <p>Are you sure you want to stop the survey <b><UntitledIfEmpty text={survey.name} entityName='survey' /></b>?</p>
      </span>,
      onConfirm: () => {
        stopSurvey(projectId, surveyId)
          .then(() => router.push(routes.surveyEdit(projectId, surveyId)))
      }
    })
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

  modeForComparison(mode: string) {
    return (<div className='mode-inline-block' key={mode}>
      <i className='material-icons'>{this.iconForMode(mode)}</i>
      <span className='mode-label name'>{modeLabel(mode)}</span>
    </div>
    )
  }

  modesForComparisons(modes: string[], index) {
    let modesForComparisons = modes.map((m, index) => {
      return this.modeForComparison(m)
    })

    let modeDescriptions
    if (modesForComparisons.length == 2) {
      modeDescriptions = [
        modesForComparisons[0],
        <div className='mode-inline-block' key='0' />,
        modesForComparisons[1],
        <div className='mode-inline-block' key='1'>fallback</div>
      ]
    } else {
      modeDescriptions = modesForComparisons
    }

    const letter = this.letterForIndex(index)
    return (
      <div className='mode' key={letter}>
        <label className='grey-text'>{'Mode ' + letter}</label>
        <div>
          {modeDescriptions}
        </div>
      </div>
    )
  }

  questionnairesColorReferences(questionnaires) {
    let questionnairesQuantity = Object.keys(questionnaires).length
    let referenceClasses = referenceBackgroundColorClasses(questionnairesQuantity)

    let colorReferences = []
    if (questionnairesQuantity > 1) {
      let i = 0
      for (var questionnaireId in questionnaires) {
        colorReferences.push((
          <div className='questionnaire-color-reference' key={questionnaireId}>
            <div className={`color-circle-reference ${referenceClasses[i]}`} />
            <div className='questionnaire-name'> {questionnaires[questionnaireId].name} </div>
          </div>
        ))
        i += 1
      }
    }

    return colorReferences
  }

  quotaBucketColorReferences(quotaBuckets) {
    let numberOfBuckets = Object.keys(quotaBuckets).length
    let referenceClasses = referenceBackgroundColorClasses(numberOfBuckets)

    let colorReferences = []
    if (numberOfBuckets > 1) {
      let i = 0
      for (var questionnaireId in quotaBuckets) {
        colorReferences.push((
          <div className='questionnaire-color-reference' key={questionnaireId}>
            <div className={`color-circle-reference ${referenceClasses[i]}`} />
            <div className='questionnaire-name'> {this.quotaBucketReferenceName(quotaBuckets[questionnaireId].condition)} </div>
          </div>
        ))
        i += 1
      }
    }

    return colorReferences
  }

  quotaBucketReferenceName(bucketConditions) {
    // console.log('bucketConditions: ', bucketConditions)
    return reduce(Object.keys(bucketConditions), (conditions, key) => {
      conditions.push([`${key}: ${bucketConditions[key]}`])
      return conditions
    }, []).join(' - ')
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
    const { questionnaires, survey, respondentsByDisposition, respondentsQuotasStats, contactedRespondents, cumulativePercentages, completionPercentage, totalRespondents, project } = this.props

    if (!survey || !cumulativePercentages || !questionnaires || !respondentsQuotasStats || !respondentsByDisposition) {
      return <p>Loading...</p>
    }

    let modes
    if (survey.mode.length == 1) {
      modes = <div className='survey-modes'>
        {survey.mode[0].map((mode, index) => (this.modeFor(index, mode)))}
      </div>
    } else {
      modes = survey.mode.map((modes, index) => (<div className='survey-modes' key={String(index)}>
        {this.modesForComparisons(modes, index)}
      </div>)
      )
    }

    let table
    if (respondentsQuotasStats && respondentsQuotasStats.buckets) {
      table = this.quotas(respondentsQuotasStats.respondentsByDisposition, respondentsQuotasStats.buckets)
    } else {
      table = this.dispositions(respondentsByDisposition, questionnaires)
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
    let colorReferences
    if (respondentsQuotasStats && respondentsQuotasStats.buckets) {
      colorReferences = this.quotaBucketColorReferences(respondentsQuotasStats.buckets)
    } else {
      colorReferences = this.questionnairesColorReferences(questionnaires)
    }

    return (
      <div className='row'>
        {stopComponent}
        <ConfirmationModal modalId='survey_show_stop_modal' ref='stopConfirmationModal' confirmationText='STOP' header='Stop survey' showCancel />
        <div className='col s12 m8'>
          <h4>
            {title}
          </h4>
          <SurveyStatus survey={survey} />
          {table}
        </div>
        <div className='col s12 m4'>
          <div className='row questionnaires-color-references'>
            {colorReferences}
          </div>

          <div className='row survey-chart'>
            <div className='col s12'>
              <label className='grey-text'>
                { completionPercentage + '% of target completed' }
              </label>
            </div>
          </div>

          <div className='row respondent-chart'>
            <div className='col s12'>
              <RespondentsChart cumulativePercentages={respondentsQuotasStats && respondentsQuotasStats.cumulativePercentages ? respondentsQuotasStats.cumulativePercentages : cumulativePercentages} />
            </div>
          </div>

          <div className='row'>
            <div className='col s12'>
              <label className='grey-text'>
                Respondents contacted
              </label>
              <div>
                { contactedRespondents + '/' + totalRespondents }
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

  groupRows(group, groupStats, questionnaires) {
    let details = groupStats.detail
    let detailsKeys = Object.keys(details)
    let questionnairesIds = Object.keys(questionnaires)
    let colorClasses = referenceColorClasses(questionnairesIds.length)

    const groupStatsByQuestionnaire = (questionnairesIds, detailsKeys, colorClasses, details) => {
      if (questionnairesIds.length > 1) {
        return questionnairesIds.map((questionnaireId, i) => {
          const totals = detailsKeys.map((detail) => details[detail].byQuestionnaire[questionnairesIds] || 0)
          return <td key={questionnaireId} className={classNames('right-align', colorClasses[i])}>{sum(totals)}</td>
        })
      }
    }
    const groupRow =
      <tr key={group}>
        <td>{capitalize(group)}</td>
        {groupStatsByQuestionnaire(questionnairesIds, detailsKeys, colorClasses, details)}
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

        let byQuestionnaire = individualStat['byQuestionnaire']
        let questionnairesColumns = null
        if (questionnairesIds.length > 1) {
          questionnairesColumns = questionnairesIds.map((questionnaireId, i) => {
            let value = null
            if (detail == 'registered') {
              value = '-'
            } else {
              value = byQuestionnaire[questionnaireId] || 0
            }

            return <td key={questionnaireId} className={classNames('right-align', colorClasses[i])}>{value}</td>
          })
        }

        return (
          <tr className='detail-row' key={detail}>
            <td>{capitalize(detail)}</td>
            {questionnairesColumns}
            <td className='right-align'>{individualStat.count}</td>
            <td className='right-align'>{this.round(individualStat.percent)}%</td>
            <td className='expand-column' />
          </tr>
        )
      })
    }

    return [groupRow, rows]
  }

  groupRowsByQuotaBucket(group, groupStats, quotaBuckets) {
    let details = groupStats.detail
    let detailsKeys = Object.keys(details)
    let quotaBucketIds = Object.keys(quotaBuckets)
    let colorClasses = referenceColorClasses(quotaBucketIds.length)

    console.log('group: ', group)
    console.log('groupStats: ', groupStats)
    console.log('quotaBuckets: ', quotaBuckets)
    console.log('this.state[group]: ', this.state[group])

    const groupStatsByQuotaBucket = (quotaBucketIds, detailsKeys, colorClasses, details) => {
      if (quotaBucketIds.length > 1) {
        return quotaBucketIds.map((quotaBucketId, i) => {
          const totals = detailsKeys.map((detail) => details[detail].byQuotaBucket[quotaBucketIds] || 0)
          return <td key={quotaBucketId} className={classNames('right-align', colorClasses[i])}>{sum(totals)}</td>
        })
      }
    }

    const groupRow =
      <tr key={group}>
        <td>{capitalize(group)}</td>
        {groupStatsByQuotaBucket(quotaBucketIds, detailsKeys, colorClasses, details)}
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

        let byQuotaBucket = individualStat.byQuotaBucket
        console.log('byQuotaBucket: ', byQuotaBucket)
        let quotaBucketColumns = null
        if (quotaBucketIds.length > 1) {
          quotaBucketColumns = quotaBucketIds.map((quotaBucketId, i) => {
            let value = null
            if (detail == 'registered') {
              value = '-'
            } else {
              value = byQuotaBucket[quotaBucketId] || 0
            }

            return <td key={quotaBucketId} className={classNames('right-align', colorClasses[i])}>{value}</td>
          })
        }

        return (
          <tr className='detail-row' key={detail}>
            <td>{capitalize(detail)}</td>
            {quotaBucketColumns}
            <td className='right-align'>{individualStat.count}</td>
            <td className='right-align'>{this.round(individualStat.percent)}%</td>
            <td className='expand-column' />
          </tr>
        )
      })
    }

    return [groupRow, rows]
  }

  dispositions(respondentsByDisposition, questionnaires) {
    const dispositionsGroup = ['responsive', 'contacted', 'uncontacted']
    let questionnairesIds = Object.keys(questionnaires)
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
                {questionnairesIds.length > 1 ? questionnairesIds.map((questionnaireId) => (<th key={questionnaireId} className='right-align' />)) : []}
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
                  return this.groupRows(group, groupStats, questionnaires)
                })
              }
            </tbody>
          </table>
        </div>
      </div>
    )
  }

  quotas(respondentsByDisposition, quotaBuckets) {
    const dispositionsGroup = ['responsive', 'contacted', 'uncontacted']
    let quotaBucketIds = Object.keys(quotaBuckets)
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
                {quotaBucketIds.length > 1 ? quotaBucketIds.map((quotaBucketId) => (<th key={quotaBucketId} className='right-align' />)) : []}
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
                  return this.groupRowsByQuotaBucket(group, groupStats, quotaBuckets)
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
  let completionPercentage = 0

  if (respondentsStatsRoot) {
    respondentsByDisposition = respondentsStatsRoot.respondentsByDisposition
    cumulativePercentages = respondentsStatsRoot.cumulativePercentages
    contactedRespondents = respondentsStatsRoot.contactedRespondents
    totalRespondents = respondentsStatsRoot.totalRespondents
    completionPercentage = respondentsStatsRoot.completionPercentage
  }

  return ({
    projectId: ownProps.params.projectId,
    project: state.project.data,
    surveyId: ownProps.params.surveyId,
    survey: state.survey.data,
    questionnaires: !state.survey.data ? {} : state.survey.data.questionnaires,
    respondentsStats: state.respondentsStats[ownProps.params.surveyId] || { cumulativePercentages: {} },
    respondentsByDisposition: respondentsByDisposition,
    respondentsQuotasStats: state.respondentsQuotasStats,
    cumulativePercentages: cumulativePercentages,
    contactedRespondents: contactedRespondents,
    totalRespondents: totalRespondents,
    completionPercentage: completionPercentage
  })
}

export default withRouter(connect(mapStateToProps)(SurveyShow))
