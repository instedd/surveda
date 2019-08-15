// @flow
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import values from 'lodash/values'
import * as actions from '../../actions/surveys'
import * as surveyActions from '../../actions/survey'
import * as projectActions from '../../actions/project'
import * as folderActions from '../../actions/folder'
import { EmptyPage, ConfirmationModal, PagingFooter, FABButton, Tooltip, EditableTitleLabel } from '../ui'
import { Button } from 'react-materialize'
import FolderCard from '../folders/FolderCard'
import SurveyCard from './SurveyCard'
import * as channelsActions from '../../actions/channels'
import * as respondentActions from '../../actions/respondents'
import CreateFolderForm from './CreateFolderForm'
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
    loadingFolder: PropTypes.bool,
    loadingFolders: PropTypes.bool,
    loadingSurveys: PropTypes.bool,
    startIndex: PropTypes.number.isRequired,
    endIndex: PropTypes.number.isRequired,
    totalCount: PropTypes.number.isRequired,
    respondentsStats: PropTypes.object.isRequired
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
    .then(value => {
      for (const surveyId in value) {
        if (value[surveyId].state != 'not_ready') {
          dispatch(respondentActions.fetchRespondentsStats(projectId, surveyId))
        }
      }
    })
    dispatch(channelsActions.fetchChannels())
    dispatch(folderActions.fetchFolders(projectId))
  }

  newSurvey() {
    const { dispatch, projectId, router } = this.props
    dispatch(surveyActions.createSurvey(projectId)).then(survey =>
      router.push(routes.surveyEdit(projectId, survey))
    )
  }

  changeFolderName(name) {
    this.setState({folderName: name})
  }

  newFolder() {
    const createFolderConfirmationModal: ConfirmationModal = this.refs.createFolderConfirmationModal
    const { dispatch, projectId } = this.props
    const modalText = <CreateFolderForm projectId={projectId} onChangeName={name => this.changeFolderName(name)} onCreate={() => { createFolderConfirmationModal.close(); this.initialFetch() }} />
    createFolderConfirmationModal.open({
      modalText: modalText,
      onConfirm: async () => {
        const { folderName } = this.state
        const res = await dispatch(folderActions.createFolder(projectId, folderName))
        if (res.errors) return false
      }
    })
  }

  deleteFolder = (id) => {
    const { dispatch, projectId } = this.props
    dispatch(folderActions.deleteFolder(projectId, id))
  }

  renameFolder = (id, name) => {
    const renameFolderConfirmationModal: ConfirmationModal = this.refs.renameFolderConfirmationModal
    const { dispatch, projectId, t } = this.props

    const onSubmit = value => {
      dispatch(folderActions.renameFolder(projectId, id, value))
      renameFolderConfirmationModal.close()
    }

    const modalText = <EditableTitleLabel title={name} entityName='folder' onSubmit={onSubmit} emptyText={t('Untitled folder')} showCancel={false} />
    renameFolderConfirmationModal.open({
      modalText: modalText
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
    const { folders, loadingFolder, loadingFolders, loadingSurveys, surveys, respondentsStats, project, startIndex, endIndex, totalCount, t } = this.props
    if ((!surveys && loadingSurveys) || (!folders && loadingFolders)) {
      return (
        <div>{t('Loading surveys...')}</div>
      )
    }

    const footer = <PagingFooter
      {...{startIndex, endIndex, totalCount}}
      onPreviousPage={() => this.previousPage()}
      onNextPage={() => this.nextPage()} />

    const readOnly = !project || project.readOnly

    let addButton = null
    if (!readOnly) {
      addButton = (
        <FABButton icon={'add'} hoverEnabled={false} text='Add survey'>
          <Tooltip text='Survey' position='left'>
            <Button onClick={() => this.newSurvey()} className='btn-floating btn-small waves-effect waves-light right mbottom white black-text' >
              <i className='material-icons black-text'>assignment_turned_in</i>
            </Button>
          </Tooltip>
          <Tooltip text='Folder' position='left'>
            <Button onClick={() => this.newFolder()} className='btn-floating btn-small waves-effect waves-light right mbottom white black-text' >
              <i className='material-icons black-text'>folder</i>
            </Button>
          </Tooltip>

        </FABButton>
      )
    }

    return (
      <div>
        {addButton}
        { (surveys && surveys.length == 0 && folders && folders.length === 0)
        ? <EmptyPage icon='assignment_turned_in' title={t('You have no surveys on this project')} onClick={(e) => this.newSurvey()} readOnly={readOnly} createText={t('Create one', {context: 'survey'})} />
        : (
          <div>
            <div className='row'>
              { folders && folders.map(folder => <FolderCard key={folder.id} {...folder} t={t} onDelete={this.deleteFolder} onRename={this.renameFolder} />)}
            </div>
            <div className='row'>
              { surveys && surveys.map(survey => {
                return (
                  <SurveyCard survey={survey} respondentsStats={respondentsStats[survey.id]} key={survey.id} readOnly={readOnly} t={t} />
                )
              }) }
            </div>
            { footer }
          </div>
        )
        }
        <ConfirmationModal disabled={loadingFolder} modalId='survey_index_folder_create' ref='createFolderConfirmationModal' confirmationText={t('Create')} header={t('Create Folder')} showCancel />
        <ConfirmationModal modalId='survey_index_folder_rename' ref='renameFolderConfirmationModal' header={t('Rename Folder')} showCancel={false} />
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  // Right now we show all surveys: they are not paginated nor sorted
  let surveys = state.surveys.items
  if (surveys) {
    surveys = values(surveys)
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

  return {
    projectId: ownProps.params.projectId,
    project: state.project.data,
    surveys,
    channels: state.channels.items,
    respondentsStats: state.respondentsStats,
    startIndex,
    endIndex,
    totalCount,
    loadingSurveys: state.surveys.fetching,
    loadingFolder: state.folder.loading,
    loadingFolders: state.folder.loadingFetch,
    folders: state.folder.folders && Object.values(state.folder.folders)
  }
}

export default translate()(withRouter(connect(mapStateToProps)(SurveyIndex)))
