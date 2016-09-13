import React, { PropTypes } from 'react'
import merge from 'lodash/merge'
import { Link } from 'react-router'

const SurveyForm = ({ onSubmit, survey, children, project }) => {
  let linkPath = `/projects/${project.id}/surveys/${survey.id}/edit/`
  return (
    <div className="white">
      <div className="row">
        <div className="col s12 m4">
          <ul className="collection with-header wizard">
            <li className="collection-header">
              <h5>Progress <span className="right">20%</span></h5>
              <p>Complete the following tasks to get your Survey ready.</p>
              <div className="progress">
                <div className="determinate" style={{width: '20%'}}></div>
              </div>
            </li>
            <li className="collection-item active">
              <Link to={`${linkPath}questionnaire`}>
                <i className="material-icons">assignment</i>
                <span>Select a questionnaire</span>
                <span className="arrowright">
                  <i className="material-icons">keyboard_arrow_right</i>
                </span>
              </Link>
            </li>
            <li className="collection-item">
              <Link to={`${linkPath}respondents`}>
                <i className="material-icons">group</i>
                <span>Upload your respondents list</span>
                <span className="arrowright">
                  <i className="material-icons">keyboard_arrow_right</i>
                </span>
              </Link>
            </li>
            <li className="collection-item">
              <a href="#!">
                <i className="material-icons">settings_input_antenna</i>
                <span>Select mode and channels</span>
                <span className="arrowright">
                  <i className="material-icons">keyboard_arrow_right</i>
                </span>
              </a>
            </li>
            <li className="collection-item">
              <a href="#!">
                <i className="material-icons">remove_circle</i>
                <span>Setup cutoff rules</span>
                <span className="arrowright">
                  <i className="material-icons">keyboard_arrow_right</i>
                </span>
              </a>
            </li>
            <li className="collection-item">
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
            </li>

          </ul>
        </div>
        {children}
      </div>
    </div>
  )
}

SurveyForm.propTypes = {
  project: PropTypes.object.isRequired,
  survey: PropTypes.object.isRequired
}

export default SurveyForm
