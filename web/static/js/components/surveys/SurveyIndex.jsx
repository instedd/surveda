// @flow
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import values from 'lodash/values'
import * as actions from '../../actions/surveys'
import * as surveyActions from '../../actions/survey'
import * as panelSurveyActions from '../../actions/panelSurvey'
import * as projectActions from '../../actions/project'
import * as folderActions from '../../actions/folder'
import * as panelSurveysActions from '../../actions/panelSurveys'
import {
  EmptyPage,
  ConfirmationModal,
  PagingFooter,
  MainAction,
  Action
} from '../ui'
import FolderCard from '../folders/FolderCard'
import SurveyCard from './SurveyCard'
import * as channelsActions from '../../actions/channels'
import FolderForm from './FolderForm'
import * as routes from '../../routes'
import { translate } from 'react-i18next'

type State = {
  folderName: string
}

class SurveyIndex extends Component<any, State> {
  static propTypes = {
    t: PropTypes.func,
    dispatch: PropTypes.func,
    router: PropTypes.object,
    projectId: PropTypes.any.isRequired,
    project: PropTypes.object,
    surveys: PropTypes.array,
    folders: PropTypes.array,
    loadingFolders: PropTypes.bool,
    loadingSurveys: PropTypes.bool,
    startIndex: PropTypes.number.isRequired,
    endIndex: PropTypes.number.isRequired,
    totalCount: PropTypes.number.isRequired,
    panelSurveys: PropTypes.array,
    loadingPanelSurveys: PropTypes.bool
  }

  constructor(props) {
    super(props)
    this.state = {
      folderName: ''
    }
  }

  componentWillMount() {
    this.initialFetch()
  }

  initialFetch() {
    const { dispatch, projectId } = this.props

    // Fetch project for title
    dispatch(projectActions.fetchProject(projectId))

    dispatch(actions.fetchSurveys(projectId))
    dispatch(channelsActions.fetchChannels())
    dispatch(folderActions.fetchFolders(projectId))
    dispatch(panelSurveysActions.fetchPanelSurveys(projectId))
  }

  newSurvey() {
    const { dispatch, projectId, router } = this.props
    dispatch(surveyActions.createSurvey(projectId)).then(survey =>
      router.push(routes.surveyEdit(projectId, survey))
    )
  }

  newPanelSurvey() {
    const { dispatch, projectId, router } = this.props
    dispatch(panelSurveyActions.createPanelSurvey(projectId)).then(firstOccurrence =>
      router.push(routes.surveyEdit(projectId, firstOccurrence))
    )
  }

  changeFolderName(name) {
    this.setState({folderName: name})
  }

  folderModal(onDispatch, cta, ref, folderId) {
    const modal: ConfirmationModal = ref
    const { dispatch } = this.props

    const modalText = <FolderForm id={folderId} onChangeName={name => this.changeFolderName(name)} cta={cta} />
    modal.open({
      modalText: modalText,
      onConfirm: async () => {
        const { folderName } = this.state
        const { error } = await dispatch(onDispatch(folderName))
        return !error
      }
    })
  }

  newFolder() {
    const { projectId, t } = this.props
    const onDispatch = folderName => folderActions.createFolder(projectId, folderName)
    this.folderModal(onDispatch, t('Please write the name of the folder you want to create'), this.refs.createFolderConfirmationModal)
  }

  renameFolder = (id, name) => {
    const { projectId, t } = this.props
    const onDispatch = folderName => folderActions.renameFolder(projectId, id, folderName)
    this.folderModal(onDispatch, t('Please write the new folder name'), this.refs.renameFolderConfirmationModal, id)
  }

  deleteFolder = (id) => {
    const { dispatch, projectId, t } = this.props
    dispatch(folderActions.deleteFolder(projectId, id)).then(({ error }) => error ? window.Materialize.toast(t(error), 5000, 'error-toast') : null)
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
    const { folders, loadingFolders, loadingSurveys, surveys, project, startIndex, endIndex, totalCount, t, panelSurveys, loadingPanelSurveys } = this.props
    if ((!surveys && loadingSurveys) || (!folders && loadingFolders) || (!panelSurveys && loadingPanelSurveys)) {
      return (
        <div>{t('Loading surveys...')}</div>
      )
    }

    const footer = <PagingFooter
      {...{startIndex, endIndex, totalCount}}
      onPreviousPage={() => this.previousPage()}
      onNextPage={() => this.nextPage()} />

    const readOnly = !project || project.readOnly

    const mainAction = (
      <MainAction text={t('Add')} icon='add' className='survey-index-main-action'>
        <Action text={t('Survey')} icon='assignment_turned_in' onClick={() => this.newSurvey()} />
        <Action text={t('Panel Survey')} icon='repeat' onClick={() => this.newPanelSurvey()} />
        <Action text='Folder' icon='folder' onClick={() => this.newFolder()} />
      </MainAction>
    )

    return (
      <div>
        { readOnly ? null : mainAction}
        { (surveys && surveys.length == 0 && folders && folders.length === 0)
        ? <EmptyPage icon='assignment_turned_in' title={t('You have no surveys on this project')} onClick={(e) => this.newSurvey()} readOnly={readOnly} createText={t('Create one', {context: 'survey'})} />
        : (
          <div>
            <div className='survey-index-grid'>
              { folders && folders.map(folder => <FolderCard key={folder.id} {...folder} t={t} onDelete={this.deleteFolder} onRename={this.renameFolder} readOnly={readOnly} />)}
            </div>
            <div className='survey-index-grid'>
              {surveys && surveys.map(survey => (
                <SurveyCard survey={survey} key={survey.id} readOnly={readOnly} />
              ))}
            </div>
            { footer }
          </div>
        )
        }
        <ConfirmationModal modalId='survey_index_folder_create' ref='createFolderConfirmationModal' confirmationText={t('Create')} header={t('Create Folder')} showCancel />
        <ConfirmationModal modalId='survey_index_folder_rename' ref='renameFolderConfirmationModal' confirmationText={t('Rename')} header={t('Rename Folder')} showCancel />
      </div>
    )
  }
}

const surveysFromState = (state, folderId, includePanelSurveys = false) => {
  const { items } = state.surveys
  if (!items) return null
  return values(items).filter(survey =>
    survey.folderId == folderId &&
    (includePanelSurveys || !survey.panelSurveyId)
  )
}

const panelSurveysFromState = (state, folderId) => {
  const surveys = surveysFromState(state, folderId, true)
  if (!surveys) return null
  const { items } = state.panelSurveys
  if (!items) return null
  return values(items).filter(panelSurvey => panelSurvey.folderId == folderId).map(panelSurvey => ({
    ...panelSurvey,
    latestSurvey: [...panelSurvey.occurrences].pop()
  }))
}

const mergePanelSurveysIntoSurveys = (surveys, panelSurveys) => {
  if (panelSurveys == null) return surveys
  return panelSurveys.map(panelSurvey => ({
    ...panelSurvey.latestSurvey,
    folderId: panelSurvey.folderId,
    panelSurvey: panelSurvey
  })).concat(surveys)
}

export const surveyIndexProps = (state: any, { panelSurveyId, folderId }: { panelSurveyId: ?number, folderId: ?number} = {
  panelSurveyId: null,
  folderId: null
}) => {
  // If panelSurveyId, list the surveys for the panel survey view.
  // The panel survey view is the only one that shows every panel survey occurrence.
  // Other views show each panel survey grouped in a single card.
  let surveys = surveysFromState(state, folderId, !!panelSurveyId)
  if (!panelSurveyId) {
    surveys = mergePanelSurveysIntoSurveys(surveys, panelSurveysFromState(state, folderId))
  }
  const totalCount = surveys ? surveys.length : 0
  const pageIndex = state.surveys.page.index
  const pageSize = state.surveys.page.size

  if (surveys) {
    if (folderId) {
      surveys = surveys.filter(s => s.folderId == folderId)
    }

    // Sort by updated at, descending
    surveys = surveys.sort((x, y) => y.updatedAt.localeCompare(x.updatedAt))
    // Show only the current page
    surveys = surveys.slice(pageIndex, pageIndex + pageSize)
  }
  const startIndex = Math.min(totalCount, pageIndex + 1)
  const endIndex = Math.min(pageIndex + pageSize, totalCount)

  return {
    surveys,
    startIndex,
    endIndex,
    totalCount
  }
}

const mapStateToProps = (state, ownProps) => {
  const { surveys, startIndex, endIndex, totalCount } = surveyIndexProps(state)
  return {
    projectId: ownProps.params.projectId,
    project: state.project.data,
    surveys,
    channels: state.channels.items,
    startIndex,
    endIndex,
    totalCount,
    loadingSurveys: state.surveys.fetching,
    loadingFolders: state.folder.loadingFetch,
    folders: state.folder.folders && Object.values(state.folder.folders),
    panelSurveys: state.panelSurveys.items && Object.values(state.panelSurveys.items),
    loadingPanelSurveys: state.panelSurveys.fetching
  }
}

export default translate()(withRouter(connect(mapStateToProps)(SurveyIndex)))
