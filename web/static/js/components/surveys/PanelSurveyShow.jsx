// @flow
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter, Link } from 'react-router'
import * as surveysActions from '../../actions/surveys'
import * as actions from '../../actions/panelSurvey'
import * as panelSurveysActions from '../../actions/panelSurveys'
import { PagingFooter } from '../ui'
import SurveyCard from '../surveys/SurveyCard'
import * as routes from '../../routes'
import { translate } from 'react-i18next'
import { RepeatButton } from '../ui/RepeatButton'
import { newOccurrence } from '../../api'
import { surveyIndexProps } from './SurveyIndex'

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
    loadingPanelSurvey: PropTypes.bool,
    panelSurvey: PropTypes.object
  }

  componentWillMount() {
    const { dispatch, projectId, panelSurvey, panelSurveyId } = this.props

    if (!panelSurvey) {
      dispatch(actions.fetchPanelSurvey(projectId, panelSurveyId))
    }
  }

  nextPage() {
    const { dispatch } = this.props
    dispatch(surveysActions.nextSurveysPage())
  }

  previousPage() {
    const { dispatch } = this.props
    dispatch(surveysActions.previousSurveysPage())
  }

  newOccurrence() {
    const { projectId, router, panelSurvey, dispatch, panelSurveyId } = this.props

    newOccurrence(projectId, panelSurvey.id)
      .then(response => {
        const panelSurvey = response.entities.surveys[response.result]
        const survey = panelSurvey.latestOccurrence
        // An occurrence of the panel survey was created -> the panel survey has changed.
        // The Redux store must be updated with the panel survey new state.
        panelSurveysActions.updateStore(dispatch, projectId, panelSurveyId)
        router.push(routes.surveyEdit(projectId, survey.id))
      })
  }

  render() {
    const loading = this.loadingMessage()
    if (loading) {
      return loading
    }

    const { surveys, project, t, panelSurveyId } = this.props
    const readOnly = !project || project.readOnly

    if (surveys && surveys.length == 0) {
      throw Error(t('Empty panel survey'))
    }

    return (
      <div className='folder-show'>
        {readOnly || this.primaryButton()}
        {this.titleLink()}
        <div>
          <div className='survey-index-grid'>
            { surveys && surveys.map(survey => {
              return (
                <SurveyCard survey={survey} key={survey.id} readOnly={readOnly} t={t} panelSurveyId={panelSurveyId} />
              )
            }) }
          </div>
          {this.footer()}
        </div>
      </div>
    )
  }

  loadingMessage() {
    const { t, loadingPanelSurvey } = this.props
    if (loadingPanelSurvey) {
      return <div className='folder-show'>{this.titleLink()}{t('Loading panel survey...')}</div>
    }
  }

  titleLink() {
    const { t, projectId, panelSurvey } = this.props

    if (panelSurvey) {
      const to = panelSurvey.folderId
        ? routes.folder(projectId, panelSurvey.folderId)
        : routes.project(projectId)
      const name = panelSurvey.name || t('Untitled panel survey')
      return <Link to={to} className='folder-header'><i className='material-icons black-text'>arrow_back</i>{name}</Link>
    }
  }

  primaryButton() {
    const { t, panelSurvey } = this.props
    const addWaveDisabled = panelSurvey ? !panelSurvey.isRepeatable : true
    return <RepeatButton text={t('Add wave')} disabled={addWaveDisabled} onClick={() => this.newOccurrence()} />
  }

  footer() {
    const { startIndex, endIndex, totalCount } = this.props

    return <PagingFooter
      {...{startIndex, endIndex, totalCount}}
      onPreviousPage={() => this.previousPage()}
      onNextPage={() => this.nextPage()} />
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

  return {
    ...surveyIndexProps(state, panelSurvey && panelSurvey.occurrences, null),
    projectId: projectId,
    panelSurveyId,
    project: state.project.data,
    loadingPanelSurvey: state.panelSurvey.loading || state.panelSurvey.fetching,
    panelSurvey
  }
}

export default translate()(withRouter(connect(mapStateToProps)(PanelSurveyShow)))
