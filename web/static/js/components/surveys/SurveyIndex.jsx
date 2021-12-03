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
import SurveyCard from './SurveyCard'
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

const mergePanelSurveysIntoSurveys = (surveys, panelSurveys) => {
  return panelSurveys
    .map(panelSurvey => ({
      ...panelSurvey.latestOccurrence,
      panelSurvey: panelSurvey
    }))
    .concat(surveys)
}

// Merges the latest panel survey occurrence into surveys, sorts the resulting
// collection, and eventually paginates the result, generating props to display
// a list of surveys and panel surveys.
//
// At least used by the FolderShow and PanelSurveyShow components.
export const surveyIndexProps = (state: any, surveys: ?Array<Survey>, panelSurveys: ?Array<PanelSurvey>) => {
  if (surveys && panelSurveys) {
    surveys = mergePanelSurveysIntoSurveys(surveys, panelSurveys)
  }

  const totalCount = surveys ? surveys.length : 0
  const pageIndex = state.surveys.page.index
  const pageSize = state.surveys.page.size
  const startIndex = Math.min(totalCount, pageIndex + 1)
  const endIndex = Math.min(pageIndex + pageSize, totalCount)

  if (surveys) {
    // Sort by updated at, descending
    surveys = surveys.sort((x, y) => y.updatedAt.localeCompare(x.updatedAt))
    // Show only the current page
    surveys = (surveys.slice(pageIndex, pageIndex + pageSize): Array<Survey>)
  }

  return {
    surveys,
    startIndex,
    endIndex,
    totalCount
  }
}

const mapStateToProps = (state, ownProps) => {
  const { folders, surveys, panelSurveys } = state

  function values<T>(obj: ?Map<number, T>): ?Array<T> {
    if (obj) {
      return (Object.values(obj): any)
    }
  }

  return {
    ...surveyIndexProps(state, values(surveys.items), values(panelSurveys.items)),
    projectId: ownProps.params.projectId,
    project: state.project.data,
    loadingSurveys: surveys && surveys.fetching,
    loadingFolders: folders && folders.loadingFetch,
    folders: values(folders.items),
    panelSurveys: values(panelSurveys.items),
    loadingPanelSurveys: state.panelSurveys.fetching
  }
}

export default translate()(withRouter(connect(mapStateToProps)(SurveyIndex)))
