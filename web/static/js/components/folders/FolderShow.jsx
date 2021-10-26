// @flow
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter, Link } from 'react-router'
import * as actions from '../../actions/surveys'
import * as surveyActions from '../../actions/survey'
import * as projectActions from '../../actions/project'
import * as folderActions from '../../actions/folder'
import * as panelSurveysActions from '../../actions/panelSurveys'
import * as panelSurveyActions from '../../actions/panelSurvey'
import { MainAction, Action, EmptyPage, ConfirmationModal, PagingFooter } from '../ui'
import SurveyCard from '../surveys/SurveyCard'
import * as routes from '../../routes'
import { translate } from 'react-i18next'
import { surveyIndexProps } from '../surveys/SurveyIndex'

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
    params: PropTypes.object,
    folderId: PropTypes.number,
    name: PropTypes.string,
    loadingFolder: PropTypes.bool,
    loadingSurveys: PropTypes.bool,
    panelSurveys: PropTypes.array,
    loadingPanelSurveys: PropTypes.bool
  }

  componentWillMount() {
    const { dispatch, projectId } = this.props

    dispatch(projectActions.fetchProject(projectId))

    dispatch(actions.fetchSurveys(projectId))
    dispatch(folderActions.fetchFolders(projectId))
    dispatch(panelSurveysActions.fetchPanelSurveys(projectId))
  }

  newSurvey() {
    const { dispatch, router, projectId, folderId } = this.props
    dispatch(surveyActions.createSurvey(projectId, folderId)).then(survey =>
      router.push(routes.surveyEdit(projectId, survey))
    )
  }

  newPanelSurvey() {
    const { dispatch, projectId, router, folderId } = this.props
    dispatch(panelSurveyActions.createPanelSurvey(projectId, folderId)).then(firstOccurrence =>
      router.push(routes.surveyEdit(projectId, firstOccurrence))
    )
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
    const { loadingSurveys, surveys, t } = this.props

    if (!surveys && loadingSurveys) {
      return t('Loading surveys...')
    }
    return null
  }

  render() {
    const { loadingFolder, surveys, project, startIndex, endIndex, totalCount, t, name, projectId } = this.props
    const to = routes.project(projectId)
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

    const emptyFolder = surveys && surveys.length == 0

    const mainAction = (
      <MainAction text={t('Add')} icon='add' className='folder-main-action' >
        <Action text={t('Survey')} icon='assignment_turned_in' onClick={() => this.newSurvey()} />
        <Action text={t('Panel Survey')} icon='repeat' onClick={() => this.newPanelSurvey()} />
      </MainAction>
    )

    return (
      <div className='folder-show'>
        { readOnly ? null : mainAction}
        {titleLink}
        { emptyFolder
        ? <EmptyPage icon='assignment_turned_in' title={t('You have no surveys in this folder')} onClick={(e) => this.newSurvey()} readOnly={readOnly} createText={t('Create one', {context: 'survey'})} />
        : (
          <div>
            <div className='survey-index-grid'>
              { surveys && surveys.map(survey => {
                return (
                  <SurveyCard survey={survey} key={survey.id} readOnly={readOnly} />
                )
              }) }
            </div>
            { footer }
          </div>
        )
        }
        <ConfirmationModal disabled={loadingFolder} modalId='survey_index_folder_create' ref='createFolderConfirmationModal' confirmationText={t('Create')} header={t('Create Folder')} showCancel />
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  const { params, t } = ownProps
  const { projectId } = params

  const folderId = params.folderId && parseInt(params.folderId)
  if (!folderId) throw new Error(t('Missing param: folderId'))
  const { surveys, startIndex, endIndex, totalCount } = surveyIndexProps(state, {
    folderId: folderId,
    panelSurveyId: null
  })
  const folders = state.folder && state.folder.folders
  const folder = folders && folders[folderId]
  const name = folder && folder.name

  return {
    projectId: projectId,
    folderId,
    project: state.project.data,
    surveys,
    startIndex,
    endIndex,
    totalCount,
    loadingSurveys: state.surveys.fetching,
    loadingFolder: state.panelSurvey.loading || state.folder.loading,
    name,
    panelSurveys: state.panelSurveys.items && Object.values(state.panelSurveys.items),
    loadingPanelSurveys: state.panelSurveys.fetching
  }
}

export default translate()(withRouter(connect(mapStateToProps)(FolderShow)))
