// @flow
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter, Link } from 'react-router'
import * as surveysActions from '../../actions/surveys'
import * as surveyActions from '../../actions/survey'
import * as actions from '../../actions/folder'
import * as panelSurveyActions from '../../actions/panelSurvey'
import { MainAction, Action, EmptyPage, PagingFooter } from '../ui'
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
    params: PropTypes.object,

    projectId: PropTypes.any.isRequired,
    project: PropTypes.object,

    folderId: PropTypes.number,
    folder: PropTypes.object,
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

  componentDidMount() {
    const { dispatch, projectId, folderId } = this.props
    dispatch(actions.fetchFolder(projectId, folderId))
  }

  newSurvey() {
    const { dispatch, router, projectId, folderId } = this.props
    dispatch(surveyActions.createSurvey(projectId, folderId)).then(survey =>
      router.push(routes.surveyEdit(projectId, survey))
    )
  }

  newPanelSurvey() {
    const { dispatch, projectId, router, folderId } = this.props
    dispatch(panelSurveyActions.createPanelSurvey(projectId, folderId)).then(firstWave =>
      router.push(routes.surveyEdit(projectId, firstWave))
    )
  }

  nextPage() {
    const { dispatch } = this.props
    dispatch(surveysActions.nextSurveysPage())
  }

  previousPage() {
    const { dispatch } = this.props
    dispatch(surveysActions.previousSurveysPage())
  }

  render() {
    const {
      projectId,
      project,
      folder,
      surveysAndPanelSurveys,

      isLoading,
      isReadOnly,
      isEmptyView,

      startIndex,
      endIndex,
      totalCount,
      t
    } = this.props

    if (isLoading) {
      return (
        <div className='folder-show'>
          <Title project={project} projectId={projectId} folder={folder} t={t} />
          {t('Loading surveys...')}
        </div>
      )
    }

    return (
      <div className='folder-show'>
        <MainActions isReadOnly={isReadOnly} t={t}>
          <Action text={t('Survey')} icon='assignment_turned_in' onClick={() => this.newSurvey()} />
          <Action text={t('Panel Survey')} icon='repeat' onClick={() => this.newPanelSurvey()} />
        </MainActions>

        <Title projectId={projectId} folder={folder} t={t} />

        <MainView isReadOnly={isReadOnly}
                  isEmpty={isEmptyView}
                  onNew={() => this.newSurvey()}
                  t={t}>

          <SurveysGrid surveysAndPanelSurveys={surveysAndPanelSurveys}
                       isReadOnly={isReadOnly}
                       t={t} />

          <PagingFooter {...{ startIndex, endIndex, totalCount }}
                        onPreviousPage={() => this.previousPage()}
                        onNextPage={() => this.nextPage()} />
        </MainView>
      </div>
    )
  }
}

const Title = (props) => {
  const { projectId, folder, t } = props
  if (!folder) return null

  const { name } = folder
  const to = routes.project(projectId)

  return (
    <Link to={to} className='folder-header'>
      <i className='material-icons black-text'>arrow_back</i>
      {name || t('Untitled folder')}
    </Link>
  )
}

Title.propTypes = {
  projectId: PropTypes.any,
  folder: PropTypes.object,
  t: PropTypes.func
}

const MainActions = (props) => {
  const { isReadOnly, children, t } = props
  if (isReadOnly) return null

  return (
    <MainAction text={t('Add')} icon='add' className='folder-main-action'>
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
                     title={t('You have no surveys in this folder')}
                     onClick={onClick}
                     readOnly={isReadOnly}
                     createText={t('Create one', { context: 'survey' })} />)
}

EmptyView.propTypes = {
  isReadOnly: PropTypes.bool,
  onClick: PropTypes.func,
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

const mapStateToFolder = (state, folderId) => {
  let folder
  let surveys = []
  let panelSurveys = []

  if (state.folder.data && state.folder.data.id === folderId) {
    folder = state.folder.data
    surveys = folder.surveys
    panelSurveys = folder.panelSurveys
  }

  return {
    folder,
    surveys,
    panelSurveys
  }
}

const mapStateToProps = (state, ownProps) => {
  const project = state.project.data
  const { params, t } = ownProps
  const { projectId } = params
  const folderId = parseInt(params.folderId)
  if (!folderId) throw new Error(t('Missing param: folderId'))

  const {
    folder,
    surveys,
    panelSurveys
  } = mapStateToFolder(state, folderId)

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
  const isLoadingFolder = state.folder.fetching
  const isLoadingInitial = !folder

  const isLoading = isLoadingInitial || isLoadingFolder
  const isReadOnly = !project || project.readOnly
  const isEmptyView = surveys.length === 0 && panelSurveys.length === 0

  return {
    projectId: projectId,
    project,

    folderId,
    folder,
    surveys,
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

export default translate()(withRouter(connect(mapStateToProps)(FolderShow)))
