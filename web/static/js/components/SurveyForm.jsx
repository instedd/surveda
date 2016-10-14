import React, { PropTypes } from 'react'
import { CollectionItem } from '.'
import * as routes from '../routes'

const SurveyForm = ({ survey, children, project }) => {
  const questionnaireStepCompleted = survey.questionnaireId != null
  const respondentsStepCompleted = survey.respondentsCount > 0
  const channelStepCompleted = survey.channels && survey.channels.length > 0
  const cutoffStepCompleted = survey.cutoff != null
  const scheduleStepCompleted = survey.scheduleDayOfWeek != null && (survey.scheduleDayOfWeek.sun || survey.scheduleDayOfWeek.mon || survey.scheduleDayOfWeek.tue || survey.scheduleDayOfWeek.wed || survey.scheduleDayOfWeek.thu || survey.scheduleDayOfWeek.fri || survey.scheduleDayOfWeek.sat)

  const mandatorySteps = [questionnaireStepCompleted, respondentsStepCompleted, channelStepCompleted, scheduleStepCompleted]

  const numberOfCompletedSteps = mandatorySteps.filter(function(item) { return item == true }).length
  const percentage = `${(100 / mandatorySteps.length * numberOfCompletedSteps).toFixed(0)}%`

  return (
    <div className='row'>
      <div className='col s12 m4'>
        <ul className='collection with-header wizard'>
          <li className='collection-header'>
            <h5>Progress <span className='right'>{percentage}</span></h5>
            <p>Complete the following tasks to get your Survey ready.</p>
            <div className='progress'>
              <div className='determinate' style={{ width: percentage }} />
            </div>
          </li>
          <CollectionItem path={routes.editSurveyQuestionnaire(project.id, survey.id)} icon='assignment' text='Select a questionnaire' completed={questionnaireStepCompleted} />
          <CollectionItem path={routes.editSurveyRespondents(project.id, survey.id)} icon='group' text='Upload your respondents list' completed={respondentsStepCompleted} />
          <CollectionItem path={routes.editSurveyChannels(project.id, survey.id)} icon='settings_input_antenna' text='Select mode and channels' completed={channelStepCompleted} />
          <CollectionItem path={routes.editSurveySchedule(project.id, survey.id)} icon='today' text='Setup a schedule' completed={scheduleStepCompleted} />
          <CollectionItem path={routes.editSurveyCutoff(project.id, survey.id)} icon='remove_circle' text='Setup cutoff rules' completed={cutoffStepCompleted} className='optional' />

          {/*
          <li className="collection-item optional">
            <a href="#!">
              <i className="material-icons">attach_money</i>
              <span>Assign incentives</span>
              <span className="arrowright">
                <i className="material-icons">keyboard_arrow_right</i>
              </span>
            </a>
          </li>
          <li className="collection-item optional">
            <a href="#!">
              <i className="material-icons">call_split</i>
              <span>Experiments</span>
              <span className="arrowright">
                <i className="material-icons">keyboard_arrow_right</i>
              </span>
            </a>
          </li> */}

        </ul>
      </div>
      {children}
    </div>
  )
}

SurveyForm.propTypes = {
  project: PropTypes.object.isRequired,
  survey: PropTypes.object.isRequired
}

export default SurveyForm
