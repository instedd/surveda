// @flow
import React, { Children, Component, PropTypes } from 'react'
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
import { SurveyCard, PanelSurveyCard } from './SurveyCard'
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
    loadingPanelSurveys: PropTypes.bool,

    surveysAndPanelSurveys: PropTypes.array,
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
    const {
      project,
      folders,
      loadingFolders,
      surveys,
      loadingSurveys,
      panelSurveys,
      loadingPanelSurveys,
      surveysAndPanelSurveys,
      startIndex,
      endIndex,
      totalCount,
      t
    } = this.props

    const isLoading = (!surveys && loadingSurveys) ||
                      (!folders && loadingFolders) ||
                      (!panelSurveys && loadingPanelSurveys)

    if (isLoading) {
      return (<div>{ t('Loading surveys...') }</div>)
    }

    const readOnly = !project || project.readOnly

    // Empty view
    const isEmptyView = surveys && surveys.length === 0 &&
                         folders && folders.length === 0 &&
                         panelSurveys && panelSurveys.length === 0

    return (
      <div>
        <MainActions isReadOnly={readOnly}
                     newFolder={() => this.newFolder()}
                     newSurvey={() => this.newSurvey()}
                     newPanelSurvey={() => this.newPanelSurvey()}
                     t={t}/>

        <MainView isReadOnly={readOnly}
                  isEmpty={isEmptyView}
                  onNewSurvey={() => this.newSurvey()}
                  t={t}>
          <FoldersGrid folders={folders}
                       isReadOnly={readOnly}
                       onRename={() => this.renameFolder()}
                       onDelete={() => this.deleteFolder()}
                       t={t}/>

          <SurveysGrid surveysAndPanelSurveys={surveysAndPanelSurveys}
                       isReadOnly={readOnly}/>

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
  const { isReadOnly, newFolder, newSurvey, newPanelSurvey, t } = props
  return (isReadOnly)
    ? null
    : (
      <MainAction text={t('Add')} icon='add' className='survey-index-main-action'>
        <Action text={t('Survey')} icon='assignment_turned_in' onClick={newSurvey} />
        <Action text={t('Panel Survey')} icon='repeat' onClick={newPanelSurvey} />
        <Action text='Folder' icon='folder' onClick={newFolder} />
      </MainAction>
    )
}

const MainView = (props) => {
  const { isEmpty, onNewSurvey, foldersGrid, surveysGrid, footer, t, children } = props
  return (isEmpty)
    ? <EmptyView onClick={onNewSurvey} t={t}/>
    : (<div>{children}</div>)
}

const EmptyView = (props) => {
  const { isReadOnly, onClick, t } = props
  return (<EmptyPage icon='assignment_turned_in'
                     title={t('You have no surveys on this project')}
                     onClick={onClick}
                     readOnly={isReadOnly}
                     createText={t('Create one', { context: 'survey' })} />)
}

const FoldersGrid = (props) => {
  const { folders, isReadOnly, onRename, onDelete, t } = props
  return (
    <div className='survey-index-grid'>
      {folders && folders.map(folder =>
        <FolderCard key={folder.id} {...folder} t={t} onRename={onRename} onDelete={onDelete} readOnly={isReadOnly} />)}
    </div>
  )
}

const SurveysGrid = (props) => {
  const { surveysAndPanelSurveys, isReadOnly } = props

  const isPanelSurvey = function(survey) {
    return survey.hasOwnProperty('occurrences')
  }

  return (
    <div className='survey-index-grid'>
      { surveysAndPanelSurveys.map(survey =>  {
          return isPanelSurvey(survey)
            ? <PanelSurveyCard panelSurvey={survey} key={`panelsurvey-${survey.id}`} readOnly={isReadOnly} />
            : <SurveyCard survey={survey} key={`survey-${survey.id}`} readOnly={isReadOnly} />
        })}
    </div>
  )
}

// const panelSurveysFromState = (state, folderId) => {
//   const surveys = surveysFromState(state, folderId, true)
//   if (!surveys) return null
//   const { items } = state.panelSurveys
//   if (!items) return null
//   return values(items).filter(panelSurvey => panelSurvey.folderId == folderId).map(panelSurvey => ({
//     ...panelSurvey,
//     latestSurvey: [...panelSurvey.occurrences].pop()
//   }))
// }

// export const surveyIndexProps = (state: any, { panelSurveyId, folderId }: { panelSurveyId: ?number, folderId: ?number} = {
//   panelSurveyId: null,
//   folderId: null
// }) => {
//   // If panelSurveyId, list the surveys for the panel survey view.
//   // The panel survey view is the only one that shows every panel survey occurrence.
//   // Other views show each panel survey grouped in a single card.
//   let surveys = surveysFromState(state, folderId, !!panelSurveyId)
//   if (!panelSurveyId) {
//     surveys = mergePanelSurveysIntoSurveys(surveys, panelSurveysFromState(state, folderId))
//   }
//   const totalCount = surveys ? surveys.length : 0
//   const pageIndex = state.surveys.page.index
//   const pageSize = state.surveys.page.size

//   if (surveys) {
//     if (folderId) {
//       surveys = surveys.filter(s => s.folderId == folderId)
//     }

//     // Sort by updated at, descending
//     surveys = surveys.sort((x, y) => y.updatedAt.localeCompare(x.updatedAt))
//     // Show only the current page
//     surveys = surveys.slice(pageIndex, pageIndex + pageSize)
//   }
//   const startIndex = Math.min(totalCount, pageIndex + 1)
//   const endIndex = Math.min(pageIndex + pageSize, totalCount)

//   return {
//     surveys,
//     startIndex,
//     endIndex,
//     totalCount
//   }
// }

const mapStateToSurveys = (state) => {
  let { items } = state.surveys
  return items ? values(items) : []
}

const mapStateToPanelSurveys = (state) => {
  let { items } = state.panelSurveys
  return items ? values(items) : []
}

const mapStateToProps = (state, ownProps) => {
  let surveys = mapStateToSurveys(state)
  let panelSurveys = mapStateToPanelSurveys(state)

  // merge all together to sort by date
  // At the same time remove surveys inside PanelSurvey (ie waves)
  // PanelSurvey is shown as a group and its waves are not shown in this view
  // And also remove surveys inside Folders
  let surveysAndPanelSurveys = [
    ...surveys.filter(survey => (!survey.panelSurveyId && !survey.folderId)),
    ...panelSurveys
  ]

  // Sort by updated_at (descending)
  surveysAndPanelSurveys = surveysAndPanelSurveys.sort((x, y) => y.updatedAt.localeCompare(x.updatedAt))

  // pagination
  const totalCount = surveysAndPanelSurveys ? surveysAndPanelSurveys.length : 0
  const { page } = state.surveys
  const pageIndex = page.index
  const pageSize = page.size

  // Show only the current page
  surveysAndPanelSurveys = surveysAndPanelSurveys.slice(pageIndex, pageIndex + pageSize)

  const startIndex = Math.min(totalCount, pageIndex + 1)
  const endIndex = Math.min(pageIndex + pageSize, totalCount)

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
    panelSurveys,
    loadingPanelSurveys: state.panelSurveys.fetching,
    surveysAndPanelSurveys
  }
}

export default translate()(withRouter(connect(mapStateToProps)(SurveyIndex)))
