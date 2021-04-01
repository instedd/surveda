import React, { Component } from 'react'
import { translate, Trans } from 'react-i18next'

import { Link } from 'react-router'
import * as routes from '../../routes'
import * as surveyActions from '../../actions/survey'

import { Card, UntitledIfEmpty, Dropdown, DropdownItem, ConfirmationModal } from '../ui'
import RespondentsChart from '../respondents/RespondentsChart'
import SurveyStatus from '../surveys/SurveyStatus'
import MoveSurveyForm from './MoveSurveyForm'

class SurveyCard extends Component<any> {
  props: {
    t: Function,
    dispatch: Function,
    respondentsStats: Object,
    survey: Survey,
    onDelete: (survey: Survey) => void,
    readOnly: boolean,
    panelSurvey: ?Object
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
            Are you sure you want to delete the survey <b><UntitledIfEmpty text={survey.name} emptyText={t('Untitled survey')} /></b>?
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

  render() {
    const { survey, respondentsStats, readOnly, t, panelSurvey } = this.props

    let cumulativePercentages = respondentsStats ? (respondentsStats['cumulativePercentages'] || {}) : {}
    let completionPercentage = respondentsStats ? (respondentsStats['completionPercentage'] || 0) : 0

    let description = <div className='grey-text card-description'>
      {survey.description}
    </div>

    const redirectTo = panelSurvey
    ? routes.panelSurvey(panelSurvey.projectId, panelSurvey.id)
    : routes.showOrEditSurvey(survey)

    const name = panelSurvey ? panelSurvey.name : survey.name

    const surveyCard = <div className='survey-card'>
      <Card>
        <div className='card-content'>
          <div className='survey-card-status'>
            <Link className='grey-text' to={redirectTo}>
              {t('{{percentage}}% of target completed', {percentage: String(Math.round(completionPercentage))})}
            </Link>
            { readOnly || (<Dropdown className='options' dataBelowOrigin={false} label={<i className='material-icons'>more_vert</i>}>
              <DropdownItem className='dots'>
                <i className='material-icons'>more_vert</i>
              </DropdownItem>
              {
                // All occurences of the same panel survey should be always together in the same folder.
                // This is why it's forbidden to change the folder of panel survey occurrences.
                // This option is cheaper than the moving all the panel survey occurrences together.
                panelSurvey
                ? null
                : <DropdownItem>
                  <a onClick={e => this.moveSurvey()}><i className='material-icons'>folder</i>{t('Move to')}</a>
                </DropdownItem>
              }
              {
                survey.state == 'running'
                  ? null
                  : <DropdownItem>
                    <a onClick={e => this.deleteSurvey()}><i className='material-icons'>delete</i>{t('Delete')}</a>
                  </DropdownItem>
              }
            </Dropdown>
            ) }
          </div>
          <div className='card-chart'>
            <RespondentsChart cumulativePercentages={cumulativePercentages} />
          </div>
          <div className='card-status'>
            <Link className='card-title black-text truncate' title={name} to={redirectTo}>
              <UntitledIfEmpty text={name} emptyText={t('Untitled survey')} />
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
          panelSurvey
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

export default translate()(SurveyCard)
