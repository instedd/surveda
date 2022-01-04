// @flow
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter, Link } from 'react-router'
import values from 'lodash/values'
import * as actions from '../../actions/surveys'
import * as surveyActions from '../../actions/survey'
import * as projectActions from '../../actions/project'
import * as folderActions from '../../actions/folder'
import * as panelSurveysActions from '../../actions/panelSurveys'
import * as panelSurveyActions from '../../actions/panelSurvey'
import { MainAction, Action, EmptyPage, ConfirmationModal, PagingFooter } from '../ui'
import { SurveyCard, PanelSurveyCard } from '../surveys/SurveyCard'
import * as routes from '../../routes'
import { translate } from 'react-i18next'
// import { surveyIndexProps } from '../surveys/SurveyIndex'

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
    // name: PropTypes.string,
    loadingFolder: PropTypes.bool,
    loadingSurveys: PropTypes.bool,
    panelSurveys: PropTypes.array,
    loadingPanelSurveys: PropTypes.bool,
    surveysAndPanelSurveys: PropTypes.array,
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

  render() {
    const {
      project,
      projectId,
      folder,
      loadingFolder,
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
                      (!panelSurveys && loadingPanelSurveys)

    if (isLoading) {
      return (
        <div className='folder-show'>
          <Title project={project} projectId={projectId} folder={folder} />
          {t('Loading surveys...')}
        </div>
      )
    }

    // TODO: Move to mapStateToProps
    const readOnly = !project || project.readOnly
    const isEmptyView = surveys && surveys.length === 0 &&
                        panelSurveys && panelSurveys.length === 0

    return (
      <div className='folder-show'>
        <MainActions isReadOnly={readOnly} t={t}>
          <Action text={t('Survey')} icon='assignment_turned_in' onClick={() => this.newSurvey()} />
          <Action text={t('Panel Survey')} icon='repeat' onClick={() => this.newPanelSurvey()} />
        </MainActions>

        <Title project={project} projectId={projectId} folder={folder}/>

        <MainView isReadOnly={readOnly}
                  isEmpty={isEmptyView}
                  onNew={() => this.newSurvey()}
                  t={t}>

          <SurveysGrid surveysAndPanelSurveys={surveysAndPanelSurveys}
                       isReadOnly={readOnly} />

          <PagingFooter {...{ startIndex, endIndex, totalCount }}
                        onPreviousPage={() => this.previousPage()}
                        onNextPage={() => this.nextPage()} />
        </MainView>

        <ConfirmationModal disabled={loadingFolder} modalId='survey_index_folder_create' ref='createFolderConfirmationModal' confirmationText={t('Create')} header={t('Create Folder')} showCancel />
      </div>
    )
  }
}

const Title = (props) => {
  const { project, projectId, folder } = props

  return folder.name
    ? (
      <Link to={routes.project(projectId)} className='folder-header'>
        <i className='material-icons black-text'>arrow_back</i>
        {folder.name}
      </Link>)
    : null
}

const MainActions = (props) => {
  const { isReadOnly, children, t } = props
  return (isReadOnly)
    ? null
    : (
      <MainAction text={t('Add')} icon='add' className='folder-main-action'>
        {children}
      </MainAction>
    )
}

const MainView = (props) => {
  const { isReadOnly, isEmpty, onNew, t, children } = props
  return (isEmpty)
    ? <EmptyView isReadOnly={isReadOnly} onClick={onNew} t={t} />
    : (<div>{children}</div>)
}

const EmptyView = (props) => {
  const { isReadOnly, onClick, t } = props
  return (<EmptyPage icon='assignment_turned_in'
                     title={t('You have no surveys in this folder')}
                     onClick={onClick}
                     readOnly={isReadOnly}
                     createText={t('Create one', { context: 'survey' })} />)
}

const SurveysGrid = (props) => {
  const { surveysAndPanelSurveys, isReadOnly } = props

  const isPanelSurvey = function (survey) {
    return survey.hasOwnProperty('occurrences')
  }

  console.log("SurveysGrid")
  console.log(surveysAndPanelSurveys)

  return (
    <div className='survey-index-grid'>
      {surveysAndPanelSurveys.map(survey => {
        return isPanelSurvey(survey)
          ? <PanelSurveyCard panelSurvey={survey} key={`panelsurvey-${survey.id}`} readOnly={isReadOnly} />
          : <SurveyCard survey={survey} key={`survey-${survey.id}`} readOnly={isReadOnly} />
      })}
    </div>
  )
}

// const mapStateToProps = (state, ownProps) => {
//   const { params, t } = ownProps

//   const folderId = params.folderId && parseInt(params.folderId)
//   if (!folderId) throw new Error(t('Missing param: folderId'))
//   const { surveys, startIndex, endIndex, totalCount } = surveyIndexProps(state, {
//     folderId: folderId,
//     panelSurveyId: null
//   })
//   const folders = state.folder && state.folder.folders
//   const folder = folders && folders[folderId]
//   // const name = folder && folder.name

//   return {
//     projectId: ownProps.params.projectId,
//     folder,
//     project: state.project.data,
//     surveys,
//     startIndex,
//     endIndex,
//     totalCount,
//     loadingSurveys: state.surveys.fetching,
//     loadingFolder: state.panelSurvey.loading || state.folder.loading,
//     // name,
//     panelSurveys: state.panelSurveys.items && Object.values(state.panelSurveys.items),
//     loadingPanelSurveys: state.panelSurveys.fetching
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
  const { params, t } = ownProps
  const { folderId } = params

  let surveys = mapStateToSurveys(state)
  let panelSurveys = mapStateToPanelSurveys(state)

  // Merge all together to sort by date
  // At the same time remove surveys inside PanelSurvey (ie waves)
  // PanelSurvey is shown as a group and its waves are not shown in this view
  let surveysAndPanelSurveys = [
    ...surveys.filter(survey => !survey.panelSurveyId),
    ...panelSurveys
  ]

  // Keep Surveys and Panelsurveys that belongs to this folders
  surveysAndPanelSurveys = surveysAndPanelSurveys.filter(surveyOrPanelSurvey =>
    surveyOrPanelSurvey.folderId === parseInt(folderId)
  )

  // Sort by updated_at (descending)
  surveysAndPanelSurveys = surveysAndPanelSurveys.sort((x, y) =>
    y.updatedAt.localeCompare(x.updatedAt)
  )

  // pagination
  const totalCount = surveysAndPanelSurveys ? surveysAndPanelSurveys.length : 0
  const { page } = state.surveys
  const pageIndex = page.index
  const pageSize = page.size

  // Show only the current page
  surveysAndPanelSurveys = surveysAndPanelSurveys.slice(pageIndex, pageIndex + pageSize)

  const startIndex = Math.min(totalCount, pageIndex + 1)
  const endIndex = Math.min(pageIndex + pageSize, totalCount)

  const folder = state.folder &&
                 state.folder.folders &&
                 state.folder.folders[folderId]

  return {
    projectId: ownProps.params.projectId,
    project: state.project.data,

    folder,
    surveys,
    panelSurveys,
    surveysAndPanelSurveys,

    startIndex,
    endIndex,
    totalCount,

    loadingFolder: state.folder.loading, // TODO: check SurveyIndex using state.folder.loadingFetch,
    loadingSurveys: state.surveys.fetching,
    loadingPanelSurveys: state.panelSurveys.fetching
  }
}

export default translate()(withRouter(connect(mapStateToProps)(FolderShow)))
