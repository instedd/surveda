// @flow
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../../actions/surveys'
import * as surveyActions from '../../actions/survey'
import * as panelSurveyActions from '../../actions/panelSurvey'
import * as foldersActions from '../../actions/folders'
import * as panelSurveysActions from '../../actions/panelSurveys'
import {
  EmptyPage,
  ConfirmationModal,
  PagingFooter,
  MainAction,
  Action
} from '../ui'
import FolderCard from '../folders/FolderCard'
import { SurveyCard, PanelSurveyCard } from './SurveyCard'
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

    folders: PropTypes.array,
    surveys: PropTypes.array,
    panelSurveys: PropTypes.array,
    surveysAndPanelSurveys: PropTypes.array,

    isLoading: PropTypes.bool,
    isReadOnly: PropTypes.bool,
    isEmptyView: PropTypes.bool,

    startIndex: PropTypes.number.isRequired,
    endIndex: PropTypes.number.isRequired,
    totalCount: PropTypes.number.isRequired
  }

  constructor(props) {
    super(props)
    this.state = {
      folderName: ''
    }
  }

  componentDidMount() {
    const { dispatch, projectId } = this.props
    dispatch(actions.fetchSurveys(projectId))
    dispatch(foldersActions.fetchFolders(projectId))
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
    dispatch(panelSurveyActions.createPanelSurvey(projectId)).then(firstWave =>
      router.push(routes.surveyEdit(projectId, firstWave))
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
    const onDispatch = folderName => foldersActions.createFolder(projectId, folderName)
    this.folderModal(onDispatch, t('Please write the name of the folder you want to create'), this.refs.createFolderConfirmationModal)
  }

  renameFolder = (id, name) => {
    const { projectId, t } = this.props
    const onDispatch = folderName => foldersActions.renameFolder(projectId, id, folderName)
    this.folderModal(onDispatch, t('Please write the new folder name'), this.refs.renameFolderConfirmationModal, id)
  }

  deleteFolder = (id) => {
    const { dispatch, projectId, t } = this.props
    dispatch(foldersActions.deleteFolder(projectId, id)).then(({ error }) => error ? window.Materialize.toast(t(error), 5000, 'error-toast') : null)
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
    const {
      folders,
      surveysAndPanelSurveys,

      isLoading,
      isReadOnly,
      isEmptyView,

      startIndex,
      endIndex,
      totalCount,
      t
    } = this.props

    if (isLoading) return (<div>{t('Loading surveys...')}</div>)

    return (
      <div>
        <MainActions isReadOnly={isReadOnly} t={t}>
          <Action text={t('Survey')} icon={'assignment_turned_in'} onClick={() => this.newSurvey()} />
          <Action text={t('Panel Survey')} icon={'repeat'} onClick={() => this.newPanelSurvey()} />
          <Action text={t('Folder')} icon={'folder'} onClick={() => this.newFolder()} />
        </MainActions>

        <MainView isReadOnly={isReadOnly}
                  isEmpty={isEmptyView}
                  onNew={() => this.newSurvey()}
                  t={t}>
          <FoldersGrid folders={folders}
                       isReadOnly={isReadOnly}
                       onRename={() => this.renameFolder()}
                       onDelete={() => this.deleteFolder()}
                       t={t} />

          <SurveysGrid surveysAndPanelSurveys={surveysAndPanelSurveys}
                       isReadOnly={isReadOnly}
                       t={t} />

          <PagingFooter {...{ startIndex, endIndex, totalCount }}
                        onPreviousPage={() => this.previousPage()}
                        onNextPage={() => this.nextPage()} />
        </MainView>

        <ConfirmationModal modalId='survey_index_folder_create' ref='createFolderConfirmationModal' confirmationText={t('Create')} header={t('Create Folder')} showCancel />
        <ConfirmationModal modalId='survey_index_folder_rename' ref='renameFolderConfirmationModal' confirmationText={t('Rename')} header={t('Rename Folder')} showCancel />
      </div>
    )
  }
}

const MainActions = (props) => {
  const { isReadOnly, children, t } = props
  if (isReadOnly) return null

  return (
    <MainAction text={t('Add')} icon='add' className='survey-index-main-action'>
      {children}
    </MainAction>
  )
}

MainActions.propTypes = {
  isReadOnly: PropTypes.bool,
  children: PropTypes.node,
  t: PropTypes.func
}

const MainView = (props) => {
  const { isReadOnly, isEmpty, onNew, children, t } = props
  return (isEmpty)
    ? <EmptyView isReadOnly={isReadOnly} onClick={onNew} t={t} />
    : (<div>{children}</div>)
}

MainView.propTypes = {
  isReadOnly: PropTypes.bool,
  isEmpty: PropTypes.bool,
  onNew: PropTypes.func,
  children: PropTypes.node,
  t: PropTypes.func
}

const EmptyView = (props) => {
  const { isReadOnly, onClick, t } = props
  return (<EmptyPage icon='assignment_turned_in'
                     title={t('You have no surveys on this project')}
                     onClick={onClick}
                     readOnly={isReadOnly}
                     createText={t('Create one', { context: 'survey' })} />)
}

EmptyView.propTypes = {
  isReadOnly: PropTypes.bool,
  onClick: PropTypes.func,
  t: PropTypes.func
}

const FoldersGrid = (props) => {
  const { folders, isReadOnly, onRename, onDelete, t } = props
  return (
    <div className='survey-index-grid'>
      {folders && folders.map(folder =>
        <FolderCard key={`folder-${folder.id}`}
                    {...folder}
                    onRename={onRename}
                    onDelete={onDelete}
                    readOnly={isReadOnly}
                    t={t} />)}
    </div>
  )
}

FoldersGrid.propTypes = {
  folders: PropTypes.array,
  isReadOnly: PropTypes.bool,
  isEmpty: PropTypes.bool,
  onRename: PropTypes.func,
  onDelete: PropTypes.func,
  t: PropTypes.func
}

const SurveysGrid = (props) => {
  const { surveysAndPanelSurveys, isReadOnly, t } = props

  const isPanelSurvey = function(survey) {
    return survey.hasOwnProperty('latestWave')
  }

  return (
    <div className='survey-index-grid'>
      {surveysAndPanelSurveys.map(survey => {
        return isPanelSurvey(survey)
          ? <PanelSurveyCard panelSurvey={survey} key={`panelsurvey-${survey.id}`} readOnly={isReadOnly} t={t} />
          : <SurveyCard survey={survey} key={`survey-${survey.id}`} readOnly={isReadOnly} t={t} />
      })}
    </div>
  )
}

SurveysGrid.propTypes = {
  surveysAndPanelSurveys: PropTypes.array,
  isReadOnly: PropTypes.bool,
  t: PropTypes.func
}

const mapStateToFolders = (state) => {
  let { items } = state.folders
  return values(items) || []
}

const mapStateToSurveys = (state) => {
  let { items } = state.surveys
  return values(items) || []
}

const mapStateToPanelSurveys = (state) => {
  let { items } = state.panelSurveys
  return values(items) || []
}

const mapStateToProps = (state, ownProps) => {
  const project = state.project.data

  let folders = mapStateToFolders(state)
  let surveys = mapStateToSurveys(state)
  let panelSurveys = mapStateToPanelSurveys(state)

  // Merge all together and sort by updated_at (descending)
  const surveysAndPanelSurveys = [
    ...surveys,
    ...panelSurveys
  ].sort((x, y) => y.updatedAt.localeCompare(x.updatedAt))

  // pagination
  const { page } = state.surveys
  const {
    paginatedElements,
    totalCount,
    startIndex,
    endIndex
  } = paginate(surveysAndPanelSurveys, page)

  // loading, readonly and emptyview
  const isLoadingFolders = state.folders && state.folders.loadingFetch
  const isLoadingSurveys = state.surveys && state.surveys.fetching
  const isLoadingPanelSurveys = state.panelSurveys && state.panelSurveys.fetching

  const isLoading = isLoadingFolders || isLoadingSurveys || isLoadingPanelSurveys
  const isReadOnly = !project || project.readOnly
  const isEmptyView = folders.length === 0 && surveys.length === 0 && panelSurveys.length === 0

  return {
    projectId: ownProps.params.projectId,
    project,

    surveys,
    folders,
    panelSurveys,
    surveysAndPanelSurveys: paginatedElements,

    isLoading,
    isReadOnly,
    isEmptyView,

    startIndex,
    endIndex,
    totalCount
  }
}

const paginate = (surveysAndPanelSurveys: Array<Survey | PanelSurvey>, page) => {
  const totalCount = surveysAndPanelSurveys ? surveysAndPanelSurveys.length : 0
  const pageIndex = page.index
  const pageSize = page.size
  const startIndex = Math.min(totalCount, pageIndex + 1)
  const endIndex = Math.min(pageIndex + pageSize, totalCount)

  return {
    paginatedElements: (surveysAndPanelSurveys
      .slice(pageIndex, pageIndex + pageSize): Array<Survey | PanelSurvey>),
    totalCount,
    startIndex,
    endIndex
  }
}

const values = function <T>(obj: ?Map<number, T>): ?Array<T> {
  if (obj) return (Object.values(obj): any)
}

export default translate()(withRouter(connect(mapStateToProps)(SurveyIndex)))
