import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import { ScrollToTopButton, CollectionItem, ScrollToLink, Tooltip } from '../ui'
import SurveyWizardQuestionnaireStep from './SurveyWizardQuestionnaireStep'
import SurveyWizardRespondentsStep from './SurveyWizardRespondentsStep'
import SurveyWizardModeStep from './SurveyWizardModeStep'
import SurveyWizardScheduleStep from './SurveyWizardScheduleStep'
import SurveyWizardCutoffStep from './SurveyWizardCutoffStep'
import SurveyWizardComparisonsStep from './SurveyWizardComparisonsStep'
import flatMap from 'lodash/flatMap'
import uniq from 'lodash/uniq'
import sumBy from 'lodash/sumBy'
import values from 'lodash/values'
import every from 'lodash/every'
import { launchSurvey } from '../../api'
import * as routes from '../../routes'

class SurveyForm extends Component {
  static propTypes = {
    projectId: PropTypes.any.isRequired,
    survey: PropTypes.object.isRequired,
    surveyId: PropTypes.any.isRequired,
    router: PropTypes.object.isRequired,
    questionnaires: PropTypes.object,
    questionnaire: PropTypes.object,
    respondentGroups: PropTypes.object,
    respondentGroupsUploading: PropTypes.bool,
    invalidRespondents: PropTypes.object,
    channels: PropTypes.object,
    errors: PropTypes.object,
    readOnly: PropTypes.bool.isRequired
  }

  componentDidMount() {
    window.scrollTo(0, 0)
    $('.scrollspy').scrollSpy()
    const sidebar = $(this.refs.sidebar)
    sidebar.pushpin({ top: sidebar.offset().top, offset: 60 })
  }

  allModesHaveAChannel(modes, channels) {
    const selectedTypes = channels.map(channel => channel.mode)
    modes = uniq(flatMap(modes))
    return modes.filter(mode => selectedTypes.indexOf(mode) != -1).length == modes.length
  }

  launchSurvey() {
    const { projectId, surveyId, router } = this.props
    launchSurvey(projectId, surveyId)
      .then(() => router.push(routes.survey(projectId, surveyId)))
  }

  questionnairesValid(ids, questionnaires) {
    return every(ids, id => questionnaires[id] && questionnaires[id].valid)
  }

  questionnairesMatchModes(modes, ids, questionnaires) {
    return every(modes, mode =>
      every(mode, m =>
        ids && every(ids, id =>
          questionnaires[id] && questionnaires[id].modes && questionnaires[id].modes.indexOf(m) != -1)))
  }

  render() {
    const { survey, projectId, questionnaires, channels, respondentGroups, respondentGroupsUploading, invalidRespondents, errors, questionnaire, readOnly } = this.props
    const questionnaireStepCompleted = survey.questionnaireIds != null && survey.questionnaireIds.length > 0 && this.questionnairesValid(survey.questionnaireIds, questionnaires)
    const respondentsStepCompleted = respondentGroups && Object.keys(respondentGroups).length > 0 &&
      every(values(respondentGroups), group => {
        return group.channels.length > 0 && this.allModesHaveAChannel(survey.mode, group.channels)
      })

    const modeStepCompleted = survey.mode != null && survey.mode.length > 0 && this.questionnairesMatchModes(survey.mode, survey.questionnaireIds, questionnaires)
    const cutoffStepCompleted = survey.cutoff != null && survey.cutoff != ''
    const validRetryConfiguration = !errors || (!errors.smsRetryConfiguration && !errors.ivrRetryConfiguration && !errors.fallbackDelay)
    const scheduleStepCompleted =
      survey.scheduleDayOfWeek != null && (
        survey.scheduleDayOfWeek.sun ||
        survey.scheduleDayOfWeek.mon ||
        survey.scheduleDayOfWeek.tue ||
        survey.scheduleDayOfWeek.wed ||
        survey.scheduleDayOfWeek.thu ||
        survey.scheduleDayOfWeek.fri ||
        survey.scheduleDayOfWeek.sat
      ) && validRetryConfiguration
    let comparisonsStepCompleted = false

    const mandatorySteps = [questionnaireStepCompleted, respondentsStepCompleted, modeStepCompleted, scheduleStepCompleted]
    if (survey.comparisons.length > 0) {
      comparisonsStepCompleted = sumBy(survey.comparisons, c => c.ratio) == 100
      mandatorySteps.push(comparisonsStepCompleted)
    }

    const numberOfCompletedSteps = mandatorySteps.filter(item => item == true).length
    const percentage = `${(100 / mandatorySteps.length * numberOfCompletedSteps).toFixed(0)}%`

    let launchComponent = null
    if (survey.state == 'ready' && !readOnly) {
      launchComponent = (
        <Tooltip text='Launch survey'>
          <a className='btn-floating btn-large waves-effect waves-light green right mtop' style={{top: '90px', left: '-5%'}} onClick={() => this.launchSurvey()}>
            <i className='material-icons'>play_arrow</i>
          </a>
        </Tooltip>
      )
    }

    // We make most steps to be "read only" (that is, non-editable) if the server said that survey
    // is "read only" (this is for a reader user) or if the survey has already started (in which
    // case there's no point in choosing a different questionnaire and so on).
    //
    // However, for the respondents step we distinguish between "read only" and "survey started",
    // because a non-reader user can still add more respondents to an existing survey, though
    // she can, for example, change their channel.
    const surveyStarted = survey.state == 'running' || survey.state == 'completed' || survey.state == 'cancelled'

    return (
      <div className='row'>
        <div className='col s12 m4'>
          <div className='sidebar' ref='sidebar'>
            <ul className='collection with-header wizard'>
              <li className='collection-header'>
                <h5>Progress <span className='right'>{percentage}</span></h5>
                <p>
                  Complete the following tasks to get your Survey ready.
                </p>
                <div className='progress'>
                  <div className='determinate' style={{ width: percentage }} />
                </div>
              </li>
              {launchComponent}
              <CollectionItem path='#questionnaire' icon='assignment' text='Select a questionnaire' completed={!!questionnaireStepCompleted} />
              <CollectionItem path='#channels' icon='settings_input_antenna' text='Select mode' completed={!!modeStepCompleted} />
              <CollectionItem path='#respondents' icon='group' text='Upload your respondents list' completed={!!respondentsStepCompleted} />
              <CollectionItem path='#schedule' icon='today' text='Setup a schedule' completed={!!scheduleStepCompleted} />
              <CollectionItem path='#cutoff' icon='remove_circle' text='Setup cutoff rules' completed={!!cutoffStepCompleted} />
              {/* <CollectionItem path={`#`} icon='attach_money' text='Assign incentives' completed={cutoffStepCompleted} /> */}
              {survey.comparisons.length > 0
                ? <CollectionItem path='#comparisons' icon='call_split' text='Comparisons' completed={!!comparisonsStepCompleted} />
              : ''}
            </ul>
          </div>
        </div>
        <div className='col s12 m7 offset-m1 wizard-content'>
          <div id='questionnaire' className='row scrollspy'>
            <SurveyWizardQuestionnaireStep projectId={projectId} survey={survey} questionnaires={questionnaires} readOnly={readOnly || surveyStarted} />
            <ScrollToLink target='#channels'>NEXT: Select Mode and channels</ScrollToLink>
          </div>
          <div id='channels' className='row scrollspy'>
            <SurveyWizardModeStep survey={survey} questionnaires={questionnaires} readOnly={readOnly || surveyStarted} respondentGroups={respondentGroups} />
            <ScrollToLink target='#respondents'>NEXT: Upload your respondents list</ScrollToLink>
          </div>
          <div id='respondents' className='row scrollspy'>
            <SurveyWizardRespondentsStep projectId={projectId} survey={survey} channels={channels} respondentGroups={respondentGroups} respondentGroupsUploading={respondentGroupsUploading} invalidRespondents={invalidRespondents} readOnly={readOnly} surveyStarted={surveyStarted} />
            <ScrollToLink target='#schedule'>NEXT: Setup a Schedule</ScrollToLink>
          </div>
          <div id='schedule' className='row scrollspy'>
            <SurveyWizardScheduleStep survey={survey} readOnly={readOnly || surveyStarted} />
            <ScrollToLink target='#cutoff'>NEXT: Setup cutoff rules</ScrollToLink>
          </div>
          <div id='cutoff' className='row scrollspy'>
            <SurveyWizardCutoffStep survey={survey} questionnaire={questionnaire} readOnly={readOnly || surveyStarted} />
            {survey.comparisons.length > 0
            ? <ScrollToLink target='#comparisons'>NEXT: Comparisons</ScrollToLink>
            : ''}
          </div>
          {survey.comparisons.length > 0
            ? <div id='comparisons' className='row scrollspy'>
              <SurveyWizardComparisonsStep survey={survey} readOnly={readOnly || surveyStarted} />
            </div>
          : ''}
          <ScrollToTopButton />
        </div>
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  surveyId: ownProps.params.surveyId,
  errors: state.survey.errorsByPath
})

export default withRouter(connect(mapStateToProps)(SurveyForm))
