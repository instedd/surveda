import React, { Component } from 'react'
import { translate, Trans } from 'react-i18next'

import { Link } from 'react-router'
import * as routes from '../../routes'
import * as surveyActions from '../../actions/survey'
import { untitledSurveyTitle } from './SurveyTitle'
import { Card, UntitledIfEmpty, Dropdown, DropdownItem, ConfirmationModal } from '../ui'
import RespondentsChart from '../respondents/RespondentsChart'
import SurveyStatus from '../surveys/SurveyStatus'
import MoveSurveyForm from './MoveSurveyForm'

import { connect } from 'react-redux'

class SurveyCard extends Component<any> {
  props: {
    t: Function,
    dispatch: Function,
    respondentsStats: Object,
    survey: Survey,
    onDelete: (survey: Survey) => void,
    readOnly: boolean,
    panelSurveyId: ?number
  };

  constructor(props) {
    super(props)

    this.state = {
      folderId: props.survey.folderId || ''
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
    if (readOnly) return false
    return survey.isDeletable
  }

  movable() {
    const { survey, readOnly } = this.props
    if (readOnly) return false
    return survey.isMovable
  }

  actionable() {
    return this.deletable() || this.movable()
  }

  render() {
    const { survey, respondentsStats, t } = this.props
    const { panelSurvey } = survey

    let cumulativePercentages = respondentsStats ? (respondentsStats['cumulativePercentages'] || {}) : {}
    let completionPercentage = respondentsStats ? (respondentsStats['completionPercentage'] || 0) : 0

    let description = <div className='grey-text card-description'>
      {survey.description}
    </div>

    const redirectTo = panelSurvey
    ? routes.panelSurvey(panelSurvey.projectId, panelSurvey.id)
    : routes.showOrEditSurvey(survey)

    const name = panelSurvey ? panelSurvey.name : survey.name

    const actionMenu = (
      <Dropdown className='options' dataBelowOrigin={false} label={<i className='material-icons'>more_vert</i>}>
        <DropdownItem className='dots'>
          <i className='material-icons'>more_vert</i>
        </DropdownItem>
        {
          this.movable()
          ? <DropdownItem>
            <a onClick={e => this.moveSurvey()}><i className='material-icons'>folder</i>{t('Move to')}</a>
          </DropdownItem>
          : null
        }
        {
          this.deletable()
            ? <DropdownItem>
              <a onClick={e => this.deleteSurvey()}><i className='material-icons'>delete</i>{t('Delete')}</a>
            </DropdownItem>
            : null
        }
      </Dropdown>
    )

    const surveyCard = <div className='survey-card'>
      <Card>
        <div className='card-content'>
          <div className='survey-card-status'>
            <Link className='grey-text' to={redirectTo}>
              {t('{{percentage}}% of target completed', {percentage: String(Math.round(completionPercentage))})}
            </Link>
            { this.actionable() ? actionMenu : null }
          </div>
          <div className='card-chart'>
            <RespondentsChart cumulativePercentages={cumulativePercentages} />
          </div>
          <div className='card-status'>
            <Link className='card-title black-text truncate' title={name} to={redirectTo}>
              <UntitledIfEmpty text={name} emptyText={untitledSurveyTitle(survey, t)} />
            </Link>
            <Link to={redirectTo}>
              {description}
              <SurveyStatus survey={survey} short />
            </Link>
          </div>
        </div>
      </Card>
    </div>

    return (
      <div className='col s12 m6 l4'>
        {
          panelSurvey || survey.generatesPanelSurvey
          ? <div className='panel-survey-card-0'>
            <div className='panel-survey-card-1'>
              <div className='panel-survey-card-2'>
                { surveyCard }
              </div>
            </div>
          </div>
          : surveyCard
        }
        <ConfirmationModal modalId='survey_index_move_survey' ref='moveSurveyConfirmationModal' confirmationText={t('Move')} header={t('Move survey')} showCancel />
        <ConfirmationModal modalId='survey_index_delete' ref='deleteConfirmationModal' confirmationText={t('Delete')} header={t('Delete survey')} showCancel />
      </div>
    )
  }
}

export default translate()(connect()(SurveyCard))
