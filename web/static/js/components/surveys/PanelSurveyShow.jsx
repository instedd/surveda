// @flow
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter, Link } from 'react-router'
import * as actions from '../../actions/surveys'
import * as projectActions from '../../actions/project'
import * as folderActions from '../../actions/folder'
import * as panelSurveyActions from '../../actions/panelSurvey'
import * as panelSurveysActions from '../../actions/panelSurveys'
import { PagingFooter } from '../ui'
import { SurveyCard } from '../surveys/SurveyCard'
import * as routes from '../../routes'
import { translate } from 'react-i18next'
import { RepeatButton } from '../ui/RepeatButton'
import { newOccurrence } from '../../api'

class PanelSurveyShow extends Component<any, any> {
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
    panelSurveyId: PropTypes.number.isRequired,
    name: PropTypes.string,
    loadingPanelSurvey: PropTypes.bool,
    loadingSurveys: PropTypes.bool,
    panelSurvey: PropTypes.object,
    panelSurveys: PropTypes.array,
    loadingPanelSurveys: PropTypes.bool
  }

  componentWillMount() {
    const { dispatch, projectId, panelSurvey, panelSurveyId } = this.props

    dispatch(projectActions.fetchProject(projectId))

    dispatch(actions.fetchSurveys(projectId))
    dispatch(folderActions.fetchFolders(projectId))
    dispatch(panelSurveysActions.fetchPanelSurveys(projectId))
    if (!panelSurvey) {
      dispatch(panelSurveyActions.fetchPanelSurvey(projectId, panelSurveyId))
    }
  }

  newOccurrence() {
    const { projectId, router, panelSurvey, dispatch, panelSurveyId } = this.props

    newOccurrence(projectId, panelSurvey.id)
      .then(response => {
        const panelSurvey = response.entities.surveys[response.result]
        const survey = [...panelSurvey.occurrences].pop()
        // An occurrence of the panel survey was created -> the panel survey has changed.
        // The Redux store must be updated with the panel survey new state.
        panelSurveysActions.updateStore(dispatch, projectId, panelSurveyId)
        router.push(routes.surveyEdit(projectId, survey.id))
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

  // loadingMessage() {
  //   const { loadingSurveys, t, panelSurvey } = this.props

  //   if (!panelSurvey) {
  //     return t('Loading panel survey...')
  //   } else if (loadingSurveys) {
  //     return t('Loading surveys...')
  //   }
  //   return null
  // }

  render() {
    const {
      projectId,
      project,
      panelSurveyId,
      panelSurvey,
      loadingPanelSurvey,
      surveys,
      loadingSurveys,
      startIndex,
      endIndex,
      totalCount,
      t
    } = this.props


    console.log(panelSurvey)
    console.log(loadingPanelSurvey)

    const isLoading = (!panelSurvey && loadingPanelSurvey) ||
                      (!surveys && loadingSurveys)

    if (isLoading) {
      return (
        <div className='folder-show'>
          <Title projectId={projectId} panelSurvey={panelSurvey} t={t}/>
          {t('Loading panel survey...')}
        </div>
      )
    }

    const readOnly = !project || project.readOnly
    const isEmptyView = surveys && surveys.length === 0

    return (
      <div className='folder-show'>
        <MainActions isReadOnly={readOnly}>
          <RepeatButton text={t('Add wave')} disabled={!panelSurvey.isRepeatable} onClick={() => this.newOccurrence()} />
        </MainActions>

        <Title projectId={projectId} panelSurvey={panelSurvey} t={t} />

        <MainView isEmpty={isEmptyView} t={t}>
          <SurveysGrid surveys={surveys} isReadOnly={readOnly} t={t} />

          <PagingFooter {...{ startIndex, endIndex, totalCount }}
            onPreviousPage={() => this.previousPage()}
            onNextPage={() => this.nextPage()} />
        </MainView>
        <div>
        </div>
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
  return (isReadOnly)
    ? null
    : (<div>{children}</div>)
}

const MainView = (props) => {
  const { isEmpty, children, t } = props

  if (isEmpty) throw Error(t('Empty panel survey'))

  return (<div>{children}</div>)
}

const SurveysGrid = (props) => {
  const { surveys, isReadOnly, t } = props

  return (
    <div className='survey-index-grid'>
      {surveys.map(survey => {
        return (<SurveyCard survey={survey} key={survey.id} readOnly={isReadOnly} t={t} />)
      })}
    </div>
  )
}

const mapStateToSurveys = (state) => {
  return state.panelSurvey.data
    ? state.panelSurvey.data.occurrences
    : []
}

const mapStateToProps = (state, ownProps) => {
  const { params, t } = ownProps
  const { projectId, panelSurveyId } = params

  let panelSurvey = state.panelSurvey.data
  let surveys = mapStateToSurveys(state)

  // TODO: verify if there is a case where the panelSurvey's id
  // is different from the id in params
  if (panelSurvey && panelSurvey.id !== parseInt(panelSurveyId)) {
    panelSurvey = null
    surveys = []
  }

  // NOTE: we fake pagination (backend doesn't paginate, yet)
  let totalCount = surveys ? surveys.length : 0
  const pageIndex = 0
  const pageSize = totalCount
  const startIndex = Math.min(totalCount, pageIndex + 1)
  const endIndex = Math.min(pageIndex + pageSize, totalCount)

  return {
    projectId: projectId,
    project: state.project.data,

    panelSurvey,
    panelSurveyId,

    surveys,

    startIndex,
    endIndex,
    totalCount,

    loadingPanelSurvey: !panelSurvey, //state.panelSurvey.loading || state.folder.loading,
    loadingSurveys: state.surveys.fetching
  }
}

// const mapStateToProps = (state, ownProps) => {
//   const { params, t } = ownProps
//   const { projectId, panelSurveyId } = params

//   const panelSurveyId = params.panelSurveyId && parseInt(params.panelSurveyId)
//   if (!panelSurveyId) throw new Error(t('Missing param: panelSurveyId'))

//   let panelSurvey = null
//   if (state.panelSurvey.data && state.panelSurvey.data.id == panelSurveyId) {
//     panelSurvey = state.panelSurvey.data
//   }
//   const name = panelSurvey && panelSurvey.name || t('Untitled panel survey')

//   const occurrences = panelSurvey ? panelSurvey.occurrences : null

//   // NOTE: we fake pagination (backend doesn't paginate, yet)
//   let totalCount = occurrences ? occurrences.length : 0
//   const pageIndex = 0
//   const pageSize = totalCount
//   const startIndex = Math.min(totalCount, pageIndex + 1)
//   const endIndex = Math.min(pageIndex + pageSize, totalCount)

//   return {
//     projectId: projectId,
//     project: state.project.data,

//     panelSurvey,
//     panelSurveyId,

//     surveys: occurrences,

//     startIndex,
//     endIndex,
//     totalCount,

//     loadingPanelSurvey: state.panelSurvey.loading || state.folder.loading,
//     loadingSurveys: state.surveys.fetching,

//     // name,
//     // panelSurveys: state.panelSurveys.items && Object.values(state.panelSurveys.items),
//     // loadingPanelSurveys: state.panelSurveys.fetching
//   }
// }

export default translate()(withRouter(connect(mapStateToProps)(PanelSurveyShow)))
