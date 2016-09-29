import React, { PropTypes } from 'react'
import merge from 'lodash/merge'
import { Link } from 'react-router'
import { CollectionItem } from '.'

const SurveyForm = ({ onSubmit, survey, children, project }) => {
  let linkPath = `/projects/${project.id}/surveys/${survey.id}/edit/`

  let questionnaireStepCompleted = survey.questionnaireId != null
  let respondentsStepCompleted = survey.respondentsCount > 0
  let channelStepCompleted = survey.channels && survey.channels.length > 0
  let cutoffStepCompleted = survey.cutoff != null

  let steps = [questionnaireStepCompleted, respondentsStepCompleted, channelStepCompleted]

  let numberOfCompletedSteps = steps.filter(function(item){ return item == true; }).length
  let totalSteps = 3
  let percentage = `${(100/totalSteps*numberOfCompletedSteps).toFixed(0)}%`

  return (
    <div className="row">
      <div className="col s12 m4">
        <ul className="collection with-header wizard">
          <li className="collection-header">
            <h5>Progress <span className="right">{percentage}</span></h5>
            <p>Complete the following tasks to get your Survey ready.</p>
            <div className="progress">
              <div className="determinate" style={{width: percentage}}></div>
            </div>
          </li>
          <CollectionItem path={`${linkPath}questionnaire`} icon="assignment" text="Select a questionnaire" completed={questionnaireStepCompleted} />
          <CollectionItem path={`${linkPath}respondents`} icon="group" text="Upload your respondents list" completed={respondentsStepCompleted} />
          <CollectionItem path={`${linkPath}channels`}  icon="settings_input_antenna" text="Select mode and channels" completed={channelStepCompleted} />
          <li className="divider"></li>
          <CollectionItem className="optional" path={`${linkPath}cutoff`} icon="remove_circle" text="Setup cutoff rules" completed={cutoffStepCompleted} />

          {/* <li className={`collection-item ${}`}>
            <a href="#!">
              <i className="material-icons">today</i>
              <span>Setup a schedule</span>
              <span className="arrowright">
                <i className="material-icons">keyboard_arrow_right</i>
              </span>
            </a>
          </li>
          <li className="divider"></li>
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
