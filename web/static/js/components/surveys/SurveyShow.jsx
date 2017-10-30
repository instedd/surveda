// @flow
import React, { Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../../actions/survey'
import * as respondentActions from '../../actions/respondents'
import RespondentsChart from '../respondents/RespondentsChart'
import SurveyStatus from './SurveyStatus'
import * as routes from '../../routes'
import { Tooltip, Modal } from '../ui'
import { stopSurvey } from '../../api'
import capitalize from 'lodash/capitalize'
import sum from 'lodash/sum'
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
    reference: React.PropTypes.object,
    completedByDate: React.PropTypes.object,
    contactedRespondents: React.PropTypes.number,
    totalRespondents: React.PropTypes.number,
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

  modeForComparison(mode: string) {
    return (<div className='mode-inline-block' key={mode}>
      <i className='material-icons'>{this.iconForMode(mode)}</i>
      <span className='mode-label name'>{modeLabel(mode)}</span>
    </div>
    )
  }

  modesForComparisons(modes: string[]) {
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

    return modeDescriptions
  }

  colorReferences(references) {
    let numberOfKeys = Object.keys(references).length
    let referenceClasses = referenceBackgroundColorClasses(numberOfKeys)

    let colorReferences = []
    if (numberOfKeys > 1) {
      let i = 0
      for (var referenceId in references) {
        const name = references[referenceId].name ? references[referenceId].name : null
        const modes = references[referenceId].modes ? this.modesForComparisons(references[referenceId].modes) : null
        const separator = name && modes ? (<div />) : null
        colorReferences.push((
          <div className='questionnaire-color-reference' key={referenceId}>
            <div className={`color-circle-reference ${referenceClasses[i]}`} />
            <div className='questionnaire-name'> {name}{separator}{modes} </div>
          </div>
        ))
        i += 1
      }
    }

    return colorReferences
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
    const { questionnaires, survey, respondentsByDisposition, reference, contactedRespondents, cumulativePercentages, completionPercentage, totalRespondents, project } = this.props
    const { stopUnderstood } = this.state

    if (!survey || !cumulativePercentages || !questionnaires || !respondentsByDisposition || !reference) {
      return <p>Loading...</p>
    }

    let modes
    if (survey.mode.length == 1) {
      modes = <div className='survey-modes'>
        {survey.mode[0].map((mode, index) => (this.modeFor(index, mode)))}
      </div>
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

    return (
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
        <div className='col s12 m9 l8'>
          <h4>
            {title}
          </h4>
          <SurveyStatus survey={survey} />
          {this.dispositions(respondentsByDisposition, reference)}
        </div>
        <div className='col s12 m3 l4'>
          <div className='row questionnaires-color-references'>
            {this.colorReferences(reference)}
          </div>

          <div className='row survey-chart'>
            <div className='col s12'>
              <label className='grey-text'>
                { this.round(completionPercentage) + '% of target completed' }
              </label>
            </div>
          </div>

          <div className='row respondent-chart'>
            <div className='col s12'>
              <RespondentsChart cumulativePercentages={cumulativePercentages} />
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
  let completionPercentage = 0
  let reference = null

  if (respondentsStatsRoot) {
    respondentsByDisposition = respondentsStatsRoot.respondentsByDisposition
    cumulativePercentages = respondentsStatsRoot.cumulativePercentages
    contactedRespondents = respondentsStatsRoot.contactedRespondents
    totalRespondents = respondentsStatsRoot.totalRespondents
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
    reference: reference,
    completionPercentage: completionPercentage
  })
}

export default withRouter(connect(mapStateToProps)(SurveyShow))
