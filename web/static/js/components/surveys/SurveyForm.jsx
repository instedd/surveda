import React, { Component, PropTypes } from 'react'
import { CollectionItem } from '../ui'
import SurveyWizardQuestionnaireStep from './SurveyWizardQuestionnaireStep'
import SurveyWizardRespondentsStep from './SurveyWizardRespondentsStep'
import SurveyWizardChannelsStep from './SurveyWizardChannelsStep'
import SurveyWizardScheduleStep from './SurveyWizardScheduleStep'
import SurveyWizardCutoffStep from './SurveyWizardCutoffStep'

export default class SurveyForm extends Component {
  static propTypes = {
    projectId: PropTypes.number.isRequired,
    survey: PropTypes.object.isRequired,
    questionnaires: PropTypes.object,
    respondents: PropTypes.object,
    channels: PropTypes.object,
    onSubmit: PropTypes.func.isRequired
  }

  componentDidMount() {
    $(document).ready(function() {
      $('.scrollspy').scrollSpy()
      const sidebar = $('.sidebar')
      if (sidebar.offset()) {
        $('.sidebar').pushpin({ top: sidebar.offset().top })
      }
    })
  }

  render() {
    const { survey, projectId, questionnaires, onSubmit, channels, respondents } = this.props

    const questionnaireStepCompleted = survey.questionnaireId != null
    const respondentsStepCompleted = survey.respondentsCount > 0
    const channelStepCompleted = survey.channels && survey.channels.length > 0
    const cutoffStepCompleted = survey.cutoff != null
    const scheduleStepCompleted =
      survey.scheduleDayOfWeek != null && (
        survey.scheduleDayOfWeek.sun ||
        survey.scheduleDayOfWeek.mon ||
        survey.scheduleDayOfWeek.tue ||
        survey.scheduleDayOfWeek.wed ||
        survey.scheduleDayOfWeek.thu ||
        survey.scheduleDayOfWeek.fri ||
        survey.scheduleDayOfWeek.sat
      )

    const mandatorySteps = [questionnaireStepCompleted, respondentsStepCompleted, channelStepCompleted, scheduleStepCompleted]
    const numberOfCompletedSteps = mandatorySteps.filter(function(item) { return item == true }).length
    const percentage = `${(100 / mandatorySteps.length * numberOfCompletedSteps).toFixed(0)}%`

    return (
      <div className='row'>
        <div className='col s12 m4'>
          <div className='sidebar'>
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
              <CollectionItem path='#questionnaire' icon='assignment' text='Select a questionnaire' completed={questionnaireStepCompleted} />
              <CollectionItem path='#respondents' icon='group' text='Upload your respondents list' completed={respondentsStepCompleted} />
              <CollectionItem path='#channels' icon='settings_input_antenna' text='Select mode and channels' completed={channelStepCompleted} />
              <CollectionItem path='#schedule' icon='today' text='Setup a schedule' completed={scheduleStepCompleted} />
              <CollectionItem path='#cutoff' icon='remove_circle' text='Setup cutoff rules' completed={cutoffStepCompleted} />
              {/* <CollectionItem path={`#`} icon='attach_money' text='Assign incentives' completed={cutoffStepCompleted} />
            <CollectionItem className='optional' path={`#`} icon='call_split' text='Experiments' completed={scheduleStepCompleted} /> */}
            </ul>
            <div className='row'>
              <div className='col s12'>
                <button type='button' className='btn waves-effect waves-light' onClick={onSubmit}>
                Save
                </button>
              </div>
            </div>
          </div>
        </div>
        <div className='col s12 m7 offset-m1'>
          <div id='questionnaire' className='row scrollspy'>
            <SurveyWizardQuestionnaireStep projectId={projectId} survey={survey} questionnaires={questionnaires} />
          </div>
          <div id='respondents' className='row scrollspy'>
            <SurveyWizardRespondentsStep projectId={projectId} survey={survey} respondents={respondents} />
          </div>
          <div id='channels' className='row scrollspy'>
            <SurveyWizardChannelsStep channels={channels} survey={survey} />
          </div>
          <div id='schedule' className='row scrollspy'>
            <SurveyWizardScheduleStep survey={survey} />
          </div>
          <div id='cutoff' className='row scrollspy'>
            <SurveyWizardCutoffStep survey={survey} />
          </div>
        </div>
      </div>
    )
  }
}
