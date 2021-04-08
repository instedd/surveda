// @flow
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter, Link } from 'react-router'
import * as actions from '../../actions/surveys'
import * as surveyActions from '../../actions/survey'
import * as projectActions from '../../actions/project'
import * as folderActions from '../../actions/folder'
import * as panelSurveyActions from '../../actions/panelSurvey'
import * as panelSurveysActions from '../../actions/panelSurveys'
import { AddButton, EmptyPage, UntitledIfEmpty, ConfirmationModal, PagingFooter } from '../ui'
import * as respondentActions from '../../actions/respondents'
import SurveyCard from '../surveys/SurveyCard'
import * as routes from '../../routes'
import { translate, Trans } from 'react-i18next'
import { RepeatButton } from '../ui/RepeatButton'
import { repeatSurvey } from '../../api'
import { surveyIndexProps } from '../../components/surveys/SurveyIndex'

class FolderShow extends Component<any, any> {
  state = {}
  static propTypes = {
    t: PropTypes.func,
    dispatch: PropTypes.func,
    router: PropTypes.object,
    projectId: PropTypes.any.isRequired,
    project: PropTypes.object,
    surveys: PropTypes.array,
    startIndex: PropTypes.number.isRequired,
    endIndex: PropTypes.number.isRequired,
    totalCount: PropTypes.number.isRequired,
    respondentsStats: PropTypes.object.isRequired,
    params: PropTypes.object,
    folderId: PropTypes.number,
    panelSurveyId: PropTypes.number,
    name: PropTypes.string,
    loadingFolder: PropTypes.bool,
    loadingSurveys: PropTypes.bool,
    panelSurvey: PropTypes.object,
    panelSurveys: PropTypes.array,
    loadingPanelSurveys: PropTypes.bool
  }

  componentWillMount() {
    const { dispatch, projectId, panelSurvey, panelSurveyId } = this.props

    dispatch(projectActions.fetchProject(projectId))

    dispatch(actions.fetchSurveys(projectId))
    .then(value => {
      for (const surveyId in value) {
        if (value[surveyId].state != 'not_ready') {
          dispatch(respondentActions.fetchRespondentsStats(projectId, surveyId))
        }
      }
    })
    dispatch(folderActions.fetchFolders(projectId))
    dispatch(panelSurveysActions.fetchPanelSurveys(projectId))
    if (panelSurveyId && !panelSurvey) {
      dispatch(panelSurveyActions.fetchPanelSurvey(projectId, panelSurveyId))
    }
  }

  repeatSurvey() {
    const { projectId, router, panelSurvey } = this.props

    repeatSurvey(projectId, panelSurvey.latestSurveyId)
      .then(response => {
        const survey = response.entities.surveys[response.result]
        router.push(routes.surveyEdit(projectId, survey.id))
      })
  }

  newSurvey() {
    const { dispatch, router, projectId, folderId } = this.props

    dispatch(surveyActions.createSurvey(projectId, folderId)).then(survey =>
      router.push(routes.surveyEdit(projectId, survey))
    )
  }

  deleteSurvey = (survey: Survey) => {
    const deleteConfirmationModal: ConfirmationModal = this.refs.deleteConfirmationModal
    const { t } = this.props
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

  nextPage() {
    const { dispatch } = this.props
    dispatch(actions.nextSurveysPage())
  }

  previousPage() {
    const { dispatch } = this.props
    dispatch(actions.previousSurveysPage())
  }

  loadingMessage() {
    const { loadingSurveys, surveys, t, panelSurvey, panelSurveyId, panelSurveys, loadingPanelSurveys } = this.props

    if (panelSurveyId && !panelSurvey) {
      return t('Loading panel survey...')
    } else {
      if (!panelSurveys && loadingPanelSurveys) {
        return t('Loading surveys...')
      }
    }
    if (!surveys && loadingSurveys) {
      return t('Loading surveys...')
    }
    return null
  }

  render() {
    const { loadingFolder, surveys, respondentsStats, project, startIndex, endIndex, totalCount, t, name, projectId, panelSurvey, panelSurveyId } = this.props
    const to = panelSurvey && panelSurvey.folderId ? routes.folder(projectId, panelSurvey.folderId) : routes.project(projectId)
    const titleLink = name ? (<Link to={to} className='folder-header'><i className='material-icons black-text'>arrow_back</i>{name}</Link>) : null
    const loadingMessage = this.loadingMessage()
    if (loadingMessage) {
      return (
        <div className='folder-show'>{titleLink}{loadingMessage}</div>
      )
    }
    const footer = <PagingFooter
      {...{startIndex, endIndex, totalCount}}
      onPreviousPage={() => this.previousPage()}
      onNextPage={() => this.nextPage()} />

    const readOnly = !project || project.readOnly

    let primaryButton = null
    if (!readOnly) {
      if (panelSurvey) {
        primaryButton = (
          <RepeatButton text={t('Repeat survey')} disabled={!panelSurvey.isRepeatable} onClick={() => this.repeatSurvey()} />
        )
      } else {
        primaryButton = (
          <AddButton text={t('Add survey')} onClick={() => this.newSurvey()} />
        )
      }
    }

    const emptyFolder = surveys && surveys.length == 0
    if (panelSurvey && emptyFolder) {
      throw new Error(t('Empty panel survey'))
    }

    let hint = null
    if (panelSurvey) {
      hint = <div className='repeat-survey row'>
        <div className='col s12 hint'>
          {
            panelSurvey.isRepeatable
            ? t('The last occurence of the panel survey is complete, you may follow up with a new survey sent to a subset of the respondents of this panel survey')
            : t("The last occurence of the panel survey isn't complete yet. After that, you may follow up with a new survey sent to a subset of the respondents of this panel survey")
          }
        </div>
      </div>
    }

    return (
      <div className='folder-show'>
        {primaryButton}
        {titleLink}
        { emptyFolder
        ? <EmptyPage icon='assignment_turned_in' title={t('You have no surveys in this folder')} onClick={(e) => this.newSurvey()} readOnly={readOnly} createText={t('Create one', {context: 'survey'})} />
        : (
          <div>
            {hint}
            <div className='row'>
              { surveys && surveys.map(survey => {
                return (
                  <SurveyCard survey={survey} respondentsStats={respondentsStats[survey.id]} onDelete={this.deleteSurvey} key={survey.id} readOnly={readOnly} t={t} panelSurveyId={panelSurveyId} />
                )
              }) }
            </div>
            { footer }
          </div>
        )
        }
        <ConfirmationModal disabled={loadingFolder} modalId='survey_index_folder_create' ref='createFolderConfirmationModal' confirmationText={t('Create')} header={t('Create Folder')} showCancel />
        <ConfirmationModal modalId='survey_index_delete' ref='deleteConfirmationModal' confirmationText={t('Delete')} header={t('Delete survey')} showCancel />
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  const { params, t } = ownProps
  const { projectId } = params

  const folderId = params.folderId && parseInt(params.folderId)
  const panelSurveyId = params.panelSurveyId && parseInt(params.panelSurveyId)
  if (!folderId && !panelSurveyId) throw new Error(t('Missing param: folderId or panelSurveyId'))
  let panelSurvey = null
  if (state.panelSurvey.data && state.panelSurvey.data.id == panelSurveyId) {
    panelSurvey = state.panelSurvey.data
  }
  const { surveys, startIndex, endIndex, totalCount } = surveyIndexProps(state, {
    folderId: folderId || (panelSurvey && panelSurvey.folderId) || null,
    panelSurveyId: panelSurveyId || null
  })
  const folders = state.folder && state.folder.folders
  const folder = folders && folders[folderId]
  const name = (panelSurvey && (panelSurvey.name || t('Untitled survey'))) ||
    (folder && folder.name)

  return {
    projectId: projectId,
    folderId,
    panelSurveyId,
    project: state.project.data,
    surveys,
    respondentsStats: state.respondentsStats,
    startIndex,
    endIndex,
    totalCount,
    loadingSurveys: state.surveys.fetching,
    loadingFolder: state.panelSurvey.loading || state.folder.loading,
    panelSurvey,
    name,
    panelSurveys: state.panelSurveys.items && Object.values(state.panelSurveys.items),
    loadingPanelSurveys: state.panelSurveys.fetching
  }
}

export default translate()(withRouter(connect(mapStateToProps)(FolderShow)))
