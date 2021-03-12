// @flow
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter, Link } from 'react-router'
import values from 'lodash/values'
import * as actions from '../../actions/surveys'
import * as surveyActions from '../../actions/survey'
import * as projectActions from '../../actions/project'
import * as folderActions from '../../actions/folder'
import { AddButton, EmptyPage, UntitledIfEmpty, ConfirmationModal, PagingFooter } from '../ui'
import * as respondentActions from '../../actions/respondents'
import SurveyCard from '../surveys/SurveyCard'
import * as routes from '../../routes'
import { translate, Trans } from 'react-i18next'
import { RepeatButton } from '../ui/RepeatButton'
import { surveyFolder } from '../layout/HeaderContainer'

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
    name: PropTypes.string,
    loadingFolder: PropTypes.bool,
    loadingSurveys: PropTypes.bool,
    isPanelSurveyFolder: PropTypes.bool,
    surveyFolder: PropTypes.object
  }

  componentWillMount() {
    const { dispatch, projectId } = this.props

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
  }

  isPanelSurveyRepeatable() {
    const { isPanelSurveyFolder, surveys, t } = this.props
    if (!isPanelSurveyFolder || !surveys) return false
    const repeatableSurveys = surveys.filter(survey => survey.isRepeatable)

    if (repeatableSurveys.length == 1) {
      return true
    } else if (repeatableSurveys.length == 0) {
      return false
    } else {
      throw new Error(t('Multiple repeatable occurrences were found in the same panel survey'))
    }
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

  render() {
    const { loadingFolder, loadingSurveys, surveys, respondentsStats, project, startIndex, endIndex, totalCount, t, name, projectId, isPanelSurveyFolder, surveyFolder } = this.props
    const to = surveyFolder ? routes.folder(projectId, surveyFolder.id) : routes.project(projectId)
    const folder = name ? (<Link to={to} className='folder-header'><i className='material-icons black-text'>arrow_back</i>{name}</Link>) : null
    if ((!surveys && loadingSurveys)) {
      return (
        <div className='folder-show'>{folder}{t('Loading surveys...')}</div>
      )
    }

    const footer = <PagingFooter
      {...{startIndex, endIndex, totalCount}}
      onPreviousPage={() => this.previousPage()}
      onNextPage={() => this.nextPage()} />

    const readOnly = !project || project.readOnly

    let primaryButton = null
    if (!readOnly) {
      if (isPanelSurveyFolder) {
        primaryButton = (
          <RepeatButton text={t('Repeat survey')} disabled={!this.isPanelSurveyRepeatable()} onClick={() => console.log('--------Repeat!!!')} />
        )
      } else {
        primaryButton = (
          <AddButton text={t('Add survey')} onClick={() => this.newSurvey()} />
        )
      }
    }

    const emptyFolder = surveys && surveys.length == 0
    if (isPanelSurveyFolder && emptyFolder) {
      throw new Error(t('Empty panel survey'))
    }

    let hint = null
    if (isPanelSurveyFolder) {
      hint = <div className='repeat-survey row'>
        <div className='col s12 hint'>
          {
            this.isPanelSurveyRepeatable()
            ? t('The last occurence of the panel survey is complete, you may follow up with a new survey sent to a subset of the respondents of this panel survey')
            : t("The last occurence of the panel survey isn't complete yet. After that, you may follow up with a new survey sent to a subset of the respondents of this panel survey")
          }
        </div>
      </div>
    }

    return (
      <div className='folder-show'>
        {primaryButton}
        {folder}
        { emptyFolder
        ? <EmptyPage icon='assignment_turned_in' title={t('You have no surveys in this folder')} onClick={(e) => this.newSurvey()} readOnly={readOnly} createText={t('Create one', {context: 'survey'})} />
        : (
          <div>
            {hint}
            <div className='row'>
              { surveys && surveys.map(survey => {
                return (
                  <SurveyCard survey={survey} respondentsStats={respondentsStats[survey.id]} onDelete={this.deleteSurvey} key={survey.id} readOnly={readOnly} t={t} inPanelSurveyFolder={isPanelSurveyFolder} />
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

const panelSurveyName = (isPanelSurveyFolder, surveys, t) => {
  if (!isPanelSurveyFolder || !surveys) return ''
  const latestPanelSurveys = surveys.filter(survey => survey.latestPanelSurvey)

  if (latestPanelSurveys.length == 1) {
    return latestPanelSurveys[0].name
  } else if (latestPanelSurveys.length == 0) {
    throw new Error(t('No latest occurrence was found in the panel survey'))
  } else {
    throw new Error(t('Multiple latest occurrences were found in the same panel survey'))
  }
}

const mapStateToProps = (state, ownProps) => {
  const { params, t } = ownProps
  const { projectId } = params

  let folderId = params.folderId && parseInt(params.folderId)
  let panelSurveyId = params.panelSurveyId && parseInt(params.panelSurveyId)
  const isPanelSurveyFolder = !!panelSurveyId

  if (!folderId && !panelSurveyId) throw new Error(t('Missing param: folderId or panelSurveyId'))

  // Right now we show all surveys: they are not paginated nor sorted
  let surveys = state.surveys.items

  if (surveys) {
    if (isPanelSurveyFolder) {
      surveys = values(surveys).filter(s => s.panelSurveyOf == panelSurveyId)
    } else {
      surveys = values(surveys).filter(s => s.folderId == folderId)
    }
  }
  const totalCount = surveys ? surveys.length : 0
  const pageIndex = state.surveys.page.index
  const pageSize = state.surveys.page.size

  if (surveys) {
    // Sort by updated at, descending
    surveys = surveys.sort((x, y) => y.updatedAt.localeCompare(x.updatedAt))
    // Show only the current page
    surveys = values(surveys).slice(pageIndex, pageIndex + pageSize)
  }
  const startIndex = Math.min(totalCount, pageIndex + 1)
  const endIndex = Math.min(pageIndex + pageSize, totalCount)
  const folders = state.folder && state.folder.folders
  const name = isPanelSurveyFolder
  ? panelSurveyName(isPanelSurveyFolder, surveys, t)
  : state.folder.folders && state.folder.folders[folderId].name

  return {
    projectId: projectId,
    folderId,
    name: name,
    project: state.project.data,
    surveys,
    respondentsStats: state.respondentsStats,
    startIndex,
    endIndex,
    totalCount,
    loadingSurveys: state.surveys.fetching,
    loadingFolder: isPanelSurveyFolder ? false : state.folder.loading,
    isPanelSurveyFolder,
    surveyFolder: surveyFolder(null, state.surveys.items, folders, panelSurveyId)
  }
}

export default translate()(withRouter(connect(mapStateToProps)(FolderShow)))
