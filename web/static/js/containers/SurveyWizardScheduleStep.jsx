import React, { Component } from 'react'
import merge from 'lodash/merge'
import { withRouter } from 'react-router'
import { connect } from 'react-redux'
import { updateSurvey } from '../api'
import * as actions from '../actions/surveys'

class SurveyWizardScheduleStep extends Component {
  toggleDay(day) {
    const { survey, dispatch } = this.props
    updateSurvey(survey.projectId, merge({}, survey, { scheduleDayOfWeek : { [day] : !survey.scheduleDayOfWeek[day] } }))
      .then(updatedSurvey => dispatch(actions.setSurvey(updatedSurvey)))
      .catch((e) => dispatch(actions.receiveSurveysError(e)))
  }

  componentDidMount() {
    const { dispatch, projectId, survey, surveyId } = this.props

    // It can happen that the survey is loaded (because it was in the index)
    // but is not loaded with details. In that case we need to reload it
    // with details.
    if (!survey || !survey.scheduleDayOfWeek) {
      dispatch(actions.fetchSurvey(projectId, surveyId))
    }
  }

  render() {
    const { survey, days } = this.props

    // Survey might be loaded without details
    if (!survey || !survey.scheduleDayOfWeek) {
      return <div>Loading...</div>
    }
    return (
      <div className="col s12 m7 offset-m1">
        <div className="row">
          <div className="col s12">
            <h4>Set up a schedule</h4>
            <p className="flow-text">
              The schedule of your survey restricts the days and hours during which respondents will be contacted. You can also specify re-contact attempts intevals.
            </p>
          </div>
        </div>
        <div className="row">
          {days.map((day) => (
            <div className="col s1" key={day}>
              <button type="button" className={`btn-floating btn-flat btn-large waves-effect waves-light ${survey.scheduleDayOfWeek[day] ? 'green white-text' : 'grey lighten-3 grey-text text-darken-1'}`} onClick={() =>
                this.toggleDay(day)
              }>
                {day}
              </button>
            </div>
          ))}
        </div>
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  surveyId: ownProps.params.surveyId,
  survey: state.surveys[ownProps.params.surveyId],
  days: ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]
})

export default withRouter(connect(mapStateToProps)(SurveyWizardScheduleStep));
