// @flow
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter, Link } from 'react-router'
import * as surveysActions from '../../actions/surveys'
import * as actions from '../../actions/panelSurvey'
import * as panelSurveysActions from '../../actions/panelSurveys'
import { PagingFooter } from '../ui'
import { SurveyCard, PanelSurveyCard } from '../surveys/SurveyCard'
import * as routes from '../../routes'
import { translate } from 'react-i18next'
import { RepeatButton } from '../ui/RepeatButton'
import { newWave } from '../../api'

class PanelSurveyShow extends Component<any, any> {
  state = {}
  static propTypes = {
    t: PropTypes.func,
    dispatch: PropTypes.func,
    router: PropTypes.object,
    params: PropTypes.object,

    projectId: PropTypes.any.isRequired,
    project: PropTypes.object,

    panelSurveyId: PropTypes.number.isRequired,
    panelSurvey: PropTypes.object,
    surveys: PropTypes.array,
    surveysAndPanelSurveys: PropTypes.array,

    isLoading: PropTypes.bool,
    isReadOnly: PropTypes.bool,
    isEmptyView: PropTypes.bool,

    startIndex: PropTypes.number.isRequired,
    endIndex: PropTypes.number.isRequired,
    totalCount: PropTypes.number.isRequired
  }

  // componentWillMount() {
  //   const { dispatch, projectId, panelSurvey, panelSurveyId } = this.props

  //   if (!panelSurvey) {
  //     dispatch(actions.fetchPanelSurvey(projectId, panelSurveyId))
  //   }
  // }

  componentDidMount() {
    const { dispatch, projectId, panelSurveyId } = this.props
    dispatch(actions.fetchPanelSurvey(projectId, panelSurveyId))
    // dispatch(actions.fetchFolder(projectId, folderId))
  }

  nextPage() {
    const { dispatch } = this.props
    dispatch(surveysActions.nextSurveysPage())
  }

  previousPage() {
    const { dispatch } = this.props
    dispatch(surveysActions.previousSurveysPage())
  }

  newWave() {
    const { projectId, router, panelSurvey, dispatch, panelSurveyId } = this.props

    newWave(projectId, panelSurvey.id)
      .then(response => {
        const panelSurvey = response.entities.surveys[response.result]
        const survey = panelSurvey.latestOccurrence
        // A wave of the panel survey was created -> the panel survey has changed.
        // The Redux store must be updated with the panel survey new state.
        panelSurveysActions.updateStore(dispatch, projectId, panelSurveyId)
        router.push(routes.surveyEdit(projectId, survey.id))
      })
  }

  render() {
    const {
      projectId,
      project,
      panelSurveyId,
      panelSurvey,
      surveys,
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
          <Title projectId={projectId} panelSurvey={panelSurvey} t={t} />
          {t('Loading panel survey...')}
        </div>
      )
    }

    return (
      <div className='folder-show'>
        <MainActions isReadOnly={isReadOnly}>
          <RepeatButton text={t('Add wave')} disabled={!panelSurvey.isRepeatable} onClick={() => this.newWave()} />
        </MainActions>

        <Title projectId={projectId} panelSurvey={panelSurvey} t={t} />

        <MainView isEmpty={isEmptyView} t={t}>
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
  const { projectId, panelSurvey, t } = props
  if (!panelSurvey) return null

  const { folderId, name } = panelSurvey
  const to = folderId
    ? routes.folder(projectId, folderId)
    : routes.project(projectId)

  return (
    <Link to={to} className='folder-header'>
      <i className='material-icons black-text'>arrow_back</i>
      {name || t('Untitled panel survey')}
    </Link>
  )
}

const MainActions = (props) => {
  const { isReadOnly, children } = props
  if (isReadOnly) return null

  return (<div>{children}</div>)
}

const MainView = (props) => {
  const { isEmpty, children, t } = props

  if (isEmpty) throw Error(t('Empty panel survey'))

  return (<div>{children}</div>)
}

const SurveysGrid = (props) => {
  const { surveysAndPanelSurveys, isReadOnly, t } = props

  return (
    <div className='survey-index-grid'>
      {surveysAndPanelSurveys.map(survey => {
        return (<SurveyCard survey={survey} key={survey.id} readOnly={isReadOnly} t={t} />)
      })}
    </div>
  )
}

const mapStateToPanelSurvey = (state, panelSurveyId) => {
  let panelSurvey
  let surveys = []
  let panelSurveys = []

  if (state.panelSurvey.data && state.panelSurvey.data.id === panelSurveyId) {
    panelSurvey = state.panelSurvey.data
    surveys = panelSurvey.waves
  }

  return {
    panelSurvey,
    surveys,
    panelSurveys
  }
}

const mapStateToProps = (state, ownProps) => {
  const project = state.project.data
  const { params, t } = ownProps
  const { projectId } = params
  const panelSurveyId = params.panelSurveyId && parseInt(params.panelSurveyId)
  if (!panelSurveyId) throw new Error(t('Missing param: panelSurveyId'))

  const {
    panelSurvey,
    surveys,
    panelSurveys
  } = mapStateToPanelSurvey(state, panelSurveyId)

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
    endIndex,
  } = paginate(surveysAndPanelSurveys, page)

  // loading, readonly and emptyview
  const isLoadingPanelSurvey = state.panelSurvey.loading || state.panelSurvey.fetching
  const isLoadingInitial = !panelSurvey

  const isLoading = isLoadingInitial || isLoadingPanelSurvey
  const isReadOnly = !project || project.readOnly
  const isEmptyView = surveys.length === 0 && panelSurveys.length === 0

  return {
    projectId: projectId,
    project,

    panelSurveyId,
    panelSurvey,
    surveys, // the surveys are the PanelSurvey's waves
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
    paginatedElements:
      (surveysAndPanelSurveys.slice(pageIndex, pageIndex + pageSize): Array<Survey| PanelSurvey >),
    totalCount,
    startIndex,
    endIndex,
  }
}

export default translate()(withRouter(connect(mapStateToProps)(PanelSurveyShow)))
