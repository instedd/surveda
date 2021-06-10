// @flow
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter, Link } from 'react-router'
import * as actions from '../../actions/surveys'
import * as surveyActions from '../../actions/survey'
import * as projectActions from '../../actions/project'
import * as folderActions from '../../actions/folder'
import * as panelSurveyActions from '../../actions/panelSurvey'
import * as panelSurveysActions from '../../actions/panelSurveys'
import { EmptyPage, UntitledIfEmpty, ConfirmationModal, PagingFooter } from '../ui'
import * as respondentActions from '../../actions/respondents'
import SurveyCard from '../surveys/SurveyCard'
import * as routes from '../../routes'
import { translate, Trans } from 'react-i18next'

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
    respondentsStats: PropTypes.object.isRequired,
    params: PropTypes.object,
    folderId: PropTypes.number,
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
    .then(value => {
      for (const surveyId in value) {
        if (value[surveyId].state != 'not_ready') {
          dispatch(respondentActions.fetchRespondentsStats(projectId, surveyId))
        }
      }
    })
    dispatch(folderActions.fetchFolders(projectId))
    dispatch(panelSurveysActions.fetchPanelSurveys(projectId))
    if (!panelSurvey) {
      dispatch(panelSurveyActions.fetchPanelSurvey(projectId, panelSurveyId))
    }
  }

  newSurvey() {
    const { dispatch, router, projectId, folderId } = this.props

    dispatch(surveyActions.createSurvey(projectId, folderId)).then(survey =>
      router.push(routes.surveyEdit(projectId, survey))
    )
  }

  deleteSurvey = (survey: Survey) => {
    const deleteConfirmationModal: ConfirmationModal = this.refs.deleteConfirmationModal
    const { t } = this.props
    deleteConfirmationModal.open({
      modalText: <span>
        <p>
          <Trans>
            Are you sure you want to delete the survey <b><UntitledIfEmpty text={survey.name} emptyText={t('Untitled survey')} /></b>?
          </Trans>
        </p>
        <p>{t('All the respondent information will be lost and cannot be undone.')}</p>
      </span>,
      onConfirm: () => {
        const { dispatch } = this.props
        dispatch(surveyActions.deleteSurvey(survey))
      }
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

  loadingMessage() {
    const { loadingSurveys, t, panelSurvey } = this.props

    if (!panelSurvey) {
      return t('Loading panel survey...')
    } else if (loadingSurveys) {
      return t('Loading surveys...')
    }
    return null
  }

  render() {
    const { surveys, respondentsStats, project, startIndex, endIndex, totalCount, t, projectId, panelSurvey } = this.props
    const to = panelSurvey
      ? panelSurvey.folderId
        ? routes.folder(projectId, panelSurvey.folderId)
        : routes.project(projectId)
      : null
    const titleLink = panelSurvey ? (<Link to={to} className='folder-header'><i className='material-icons black-text'>arrow_back</i>{panelSurvey.name || t('Untitled panel survey')}</Link>) : null
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

    const empty = surveys && surveys.length == 0

    return (
      <div className='folder-show'>
        {titleLink}
        { empty
        ? <EmptyPage icon='warning' title={t('You have no surveys in this panelSurvey')} />
        : (
          <div>
            <div className='survey-index-grid'>
              { surveys && surveys.map(survey => {
                return (
                  <SurveyCard survey={survey} respondentsStats={respondentsStats[survey.id]} onDelete={this.deleteSurvey} key={survey.id} readOnly={readOnly} t={t} />
                )
              }) }
            </div>
            { footer }
          </div>
        )
        }
        <ConfirmationModal modalId='survey_index_delete' ref='deleteConfirmationModal' confirmationText={t('Delete')} header={t('Delete survey')} showCancel />
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  const { params, t } = ownProps
  const { projectId } = params

  const panelSurveyId = params.panelSurveyId && parseInt(params.panelSurveyId)
  if (!panelSurveyId) throw new Error(t('Missing param: panelSurveyId'))
  let panelSurvey = null
  if (state.panelSurvey.data && state.panelSurvey.data.id == panelSurveyId) {
    panelSurvey = state.panelSurvey.data
  }
  const name = panelSurvey && panelSurvey.name || t('Untitled panel survey')

  const occurrences = panelSurvey ? panelSurvey.occurrences : null
  let totalCount = occurrences ? occurrences.length : 0
  const pageIndex = 0
  const pageSize = 0
  const startIndex = Math.min(totalCount, pageIndex + 1)
  const endIndex = Math.min(pageIndex + pageSize, totalCount)

  return {
    projectId: projectId,
    panelSurveyId,
    project: state.project.data,
    surveys: occurrences,
    respondentsStats: state.respondentsStats,
    startIndex,
    endIndex,
    totalCount,
    loadingSurveys: state.surveys.fetching,
    loadingPanelSurvey: state.panelSurvey.loading || state.folder.loading,
    panelSurvey,
    name,
    panelSurveys: state.panelSurveys.items && Object.values(state.panelSurveys.items),
    loadingPanelSurveys: state.panelSurveys.fetching
  }
}

export default translate()(withRouter(connect(mapStateToProps)(PanelSurveyShow)))
