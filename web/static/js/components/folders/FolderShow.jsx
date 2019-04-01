// @flow
import React, { Component, PureComponent, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter, Link } from 'react-router'
import values from 'lodash/values'
import * as actions from '../../actions/surveys'
import * as surveyActions from '../../actions/survey'
import * as projectActions from '../../actions/project'
import * as folderActions from '../../actions/folder'
import { AddButton, Card, EmptyPage, UntitledIfEmpty, ConfirmationModal, PagingFooter, FABButton, Tooltip } from '../ui'
import { Button } from 'react-materialize'
import * as channelsActions from '../../actions/channels'
import * as respondentActions from '../../actions/respondents'
import RespondentsChart from '../respondents/RespondentsChart'
import SurveyStatus from '../surveys/SurveyStatus'
import SurveyCard from '../surveys/SurveyCard'
import * as routes from '../../routes'
import { translate, Trans } from 'react-i18next'

class FolderShow extends Component<any> {
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
    respondentsStats: PropTypes.object.isRequired
  }

  componentWillMount () {
    const { dispatch } = this.props
    const { projectId, folderId } = this.props.params

    dispatch(projectActions.fetchProject(projectId, folderId))

    dispatch(actions.fetchSurveys(projectId, folderId))
    .then(value => {
      for (const surveyId in value) {
        if (value[surveyId].state != 'not_ready') {
          dispatch(respondentActions.fetchRespondentsStats(projectId, surveyId))
        }
      }
    })
    dispatch(channelsActions.fetchChannels())
  }

  newSurvey() {
    const { dispatch, projectId, router, folderId } = this.props
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

  render() {
    const { loadingFolder, loadingSurveys, surveys, respondentsStats, project, startIndex, endIndex, totalCount, t } = this.props
    if ((!surveys && loadingSurveys) ) {
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
        <AddButton text={t('Add Project')} onClick={() => this.newSurvey()} />
      )
    }

    return (
      <div>
        {addButton}
        { (surveys && surveys.length == 0)
        ? <EmptyPage icon='assignment_turned_in' title={t('You have no surveys on this project')} onClick={(e) => this.newSurvey()} readOnly={readOnly} createText={t('Create one', {context: 'survey'})} />
        : (
          <div>
            <div className='row'>
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
        <ConfirmationModal disabled={loadingFolder} modalId='survey_index_folder_create' ref='createFolderConfirmationModal' confirmationText={t('Create')} header={t('Create Folder')} showCancel />
        <ConfirmationModal modalId='survey_index_delete' ref='deleteConfirmationModal' confirmationText={t('Delete')} header={t('Delete survey')} showCancel />
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
  }
}

export default translate()(withRouter(connect(mapStateToProps)(FolderShow)))
