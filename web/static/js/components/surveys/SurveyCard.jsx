import React, { Component } from 'react'
import { translate, Trans } from 'react-i18next'

import { Link } from 'react-router'
import * as routes from '../../routes'
import * as surveyActions from '../../actions/survey'
import * as panelSurveyActions from '../../actions/panelSurvey'
import { fetchRespondentsStats } from '../../actions/respondents'
import { untitledSurveyTitle } from './SurveyTitle'
import { Card, UntitledIfEmpty, Dropdown, DropdownItem, ConfirmationModal } from '../ui'
import RespondentsChart from '../respondents/RespondentsChart'
import SurveyStatus from '../surveys/SurveyStatus'
import MoveSurveyForm from './MoveSurveyForm'

import { connect } from 'react-redux'

class _SurveyCard extends Component<any> {
  props: {
    t: Function,
    dispatch: Function,
    survey: Survey,
    readOnly: boolean
  };

  constructor(props) {
    super(props)

    this.state = {
      folderId: props.survey.folderId || ''
    }
  }

  componentDidMount() {
    const { survey, dispatch } = this.props

    console.log("SurveyCard")
    console.log(dispatch)

    if (survey.state != 'not_ready') {
      fetchRespondentsStats(survey.projectId, survey.id)(dispatch)
    }
  }

  changeFolder = (folderId) => this.setState({ folderId })

  moveSurvey = () => {
    const moveSurveyConfirmationModal: ConfirmationModal = this.refs.moveSurveyConfirmationModal
    const { survey } = this.props
    const modalText = <MoveSurveyForm defaultFolderId={survey.folderId} onChangeFolderId={folderId => this.changeFolder(folderId)} />
    moveSurveyConfirmationModal.open({
      modalText: modalText,
      onConfirm: () => {
        const { dispatch } = this.props
        const { folderId } = this.state
        dispatch(surveyActions.changeFolder(survey, folderId))
      }
    })
  }

  deleteSurvey = () => {
    const deleteConfirmationModal: ConfirmationModal = this.refs.deleteConfirmationModal
    const { t, survey } = this.props
    deleteConfirmationModal.open({
      modalText: <span>
        <p>
          <Trans>
            Are you sure you want to delete the survey <b><UntitledIfEmpty text={survey.name} emptyText={untitledSurveyTitle(survey, t)} /></b>?
          </Trans>
        </p>
        <p>{t('All the respondent information will be lost and cannot be undone.')}</p>
      </span>,
      onConfirm: () => {
        const { dispatch } = this.props
        dispatch(surveyActions.deleteSurvey(survey))
      }
    })
  }

  deletable() {
    const { survey, readOnly } = this.props
    return !readOnly && survey.isDeletable
  }

  movable() {
    const { survey, readOnly } = this.props
    return !readOnly && survey.isMovable
  }

  actionable() {
    return this.deletable() || this.movable()
  }

  render() {
    const { survey, t, dispatch } = this.props
    const { panelSurvey } = survey

    let actions = []
    if (this.movable()) actions.push({ name: t('Move to'), func: this.moveSurvey })
    if (this.deletable()) actions.push({ name: t('Delete'), func: this.deleteSurvey })

    return (
      <div className='col s12 m6 l4'>
        <InnerSurveyCard survey={survey}
                         actions={actions}
                         onClickRoute={routes.showOrEditSurvey(survey)}
                         t={t}
                         dispatch={dispatch}/>

        <ConfirmationModal modalId='survey_index_move_survey' ref='moveSurveyConfirmationModal' confirmationText={t('Move')} header={t('Move survey')} showCancel />
        <ConfirmationModal modalId='survey_index_delete' ref='deleteConfirmationModal' confirmationText={t('Delete')} header={t('Delete survey')} showCancel />
      </div>
    )
  }
}
class _PanelSurveyCard extends Component<any> {
  props: {
    t: Function,
    dispatch: Function,
    panelSurvey: Survey,
    readOnly: boolean,
  };

  constructor(props) {
    super(props)

    this.state = {
      folderId: props.panelSurvey.folderId || ''
    }
  }

  lastWave() {
    const { panelSurvey } = this.props

    return [...panelSurvey.occurrences].pop() // TODO
  }

  changeFolder(folderId) {
    this.setState({ folderId })
  }

  moveSurvey = () => {
    const { panelSurvey } = this.props

    const moveSurveyConfirmationModal: ConfirmationModal = this.refs.moveSurveyConfirmationModal
    moveSurveyConfirmationModal.open({
      modalText: <MoveSurveyForm defaultFolderId={panelSurvey.folderId} onChangeFolderId={folderId => this.changeFolder(folderId)} />,
      onConfirm: () => {
        const { dispatch } = this.props
        const { folderId } = this.state
        dispatch(panelSurveyActions.changeFolder(panelSurvey, folderId))
      }
    })
  }

  deleteSurvey = () => {
    const deleteConfirmationModal: ConfirmationModal = this.refs.deleteConfirmationModal
    const { t, panelSurvey } = this.props

    const survey = this.lastWave()

    deleteConfirmationModal.open({
      modalText: <span>
        <p>
          <Trans>
            Are you sure you want to delete the last wave <b><UntitledIfEmpty text={survey.name} emptyText={untitledSurveyTitle(survey, t)} /></b>?
          </Trans>
        </p>
        <p>{t('All the respondent information will be lost and cannot be undone.')}</p>
      </span>,
      onConfirm: () => {
        const { dispatch } = this.props
        dispatch(surveyActions.deleteSurvey(survey))
      }
    })
  }

  // The option Delete on the PanelSurveyCard means:
  // delete the last wave in the PanelSurvey
  deletable() {
    const { readOnly } = this.props
    const survey = this.lastWave()

    return !readOnly && survey.isDeletable
  }

  movable() {
    const { readOnly } = this.props
    return !readOnly
  }

  actionable() {
    return this.deletable() || this.movable()
  }

  render() {
    const { panelSurvey, t, dispatch } = this.props
    const survey = this.lastWave()

    let actions = []
    if (this.movable()) actions.push({ name: t('Move to'), func: this.moveSurvey })
    if (this.deletable()) actions.push({ name: t('Delete wave'), func: this.deleteSurvey })

    return (
      <div className='col s12 m6 l4'>
        <div className='panel-survey-card-0'>
          <div className='panel-survey-card-1'>
            <div className='panel-survey-card-2'>
              <InnerSurveyCard survey={survey}
                               actions={actions}
                               onClickRoute={routes.panelSurvey(survey.projectId, panelSurvey.id)}
                               t={t}
                               dispatch={dispatch}/>
            </div>
          </div>
        </div>

        <ConfirmationModal modalId='survey_index_move_survey' ref='moveSurveyConfirmationModal' confirmationText={t('Move')} header={t('Move survey')} showCancel />
        <ConfirmationModal modalId='survey_index_delete' ref='deleteConfirmationModal' confirmationText={t('Delete')} header={t('Delete survey')} showCancel />
      </div>
    )
  }
}

class InnerSurveyCard extends Component<any> {
  props: {
    survey: Survey,
    actions: Array<Object>,
    onClickRoute: Function,
    t: Function,
    respondentsStats: ?Object,
    dispatch: Function
  };

  constructor(props) {
    super(props)
  }

  componentDidMount() {
    const { survey, dispatch } = this.props

    if (survey.state != 'not_ready') {
      fetchRespondentsStats(survey.projectId, survey.id)(dispatch)
    }
  }

  render() {
    const { survey, respondentsStats, actions, onClickRoute, t } = this.props

    // stats
    let cumulativePercentages = respondentsStats ? (respondentsStats['cumulativePercentages'] || {}) : {}
    let completionPercentage = respondentsStats ? (respondentsStats['completionPercentage'] || 0) : 0

    return (
      <div className='survey-card'>
        <Card>
          <div className='card-content'>
            <div className='survey-card-status'>
              <Link className='grey-text' to={onClickRoute}>
                {t('{{percentage}}% of target completed', { percentage: String(Math.round(completionPercentage)) })}
              </Link>
              <ActionMenu actions={actions} />
            </div>
            <div className='card-chart'>
              <RespondentsChart cumulativePercentages={cumulativePercentages} />
            </div>
            <div className='card-status'>
              <Link className='card-title black-text truncate' title={survey.name} to={onClickRoute}>
                <UntitledIfEmpty text={survey.name} emptyText={untitledSurveyTitle(survey, t)} />
              </Link>
              <Link to={onClickRoute}>
                <div className='grey-text card-description'>
                  {survey.description}
                </div>
                <SurveyStatus survey={survey} short />
              </Link>
            </div>
          </div>
        </Card>
      </div>
    )
  }
}

const ActionMenu = (props) => {
  const  { actions } = props

  if (actions.length === 0) return null

  return (
    <Dropdown className='options' dataBelowOrigin={false} label={<i className='material-icons'>more_vert</i>}>
      <DropdownItem className='dots'>
        <i className='material-icons'>more_vert</i>
      </DropdownItem>
      { actions.map((action, index) => (
        <DropdownItem key={index}>
          <a onClick={e => action.func()}>
            <i className='material-icons'>folder</i>
            {action.name}
          </a>
        </DropdownItem>
      ))}
    </Dropdown>
  )
}

export const SurveyCard = translate()(connect()(_SurveyCard))
export const PanelSurveyCard = translate()(connect()(_PanelSurveyCard))
