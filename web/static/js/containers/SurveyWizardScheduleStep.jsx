import React, { Component } from 'react'
import merge from 'lodash/merge'
import { withRouter } from 'react-router'
import { connect } from 'react-redux'
import { updateSurvey } from '../api'
import * as actions from '../actions/surveys'
import { Input } from 'react-materialize'

class SurveyWizardScheduleStep extends Component {
  toggleDay(day) {
    const { survey, dispatch } = this.props
    updateSurvey(survey.projectId, merge({}, survey, { scheduleDayOfWeek: { [day]: !survey.scheduleDayOfWeek[day] } }))
      .then(updatedSurvey => dispatch(actions.setSurvey(updatedSurvey)))
      .catch((e) => dispatch(actions.receiveSurveysError(e)))
  }

  updateFrom(event) {
    let hour = event.target.value
    const { survey, dispatch } = this.props
    updateSurvey(survey.projectId, merge({}, survey, { scheduleStartTime: hour }))
      .then(updatedSurvey => dispatch(actions.setSurvey(updatedSurvey)))
      .catch((e) => dispatch(actions.receiveSurveysError(e)))
  }

  updateTo(event) {
    let hour = event.target.value
    const { survey, dispatch } = this.props
    updateSurvey(survey.projectId, merge({}, survey, { scheduleEndTime: hour }))
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
    // Survey might be loaded without details
    const { survey, days, hours} = this.props
    let defaultFrom = (survey && survey.scheduleStartTime) ? survey.scheduleStartTime : '09:00:00'
    let defaultTo = (survey && survey.scheduleEndTime) ? survey.scheduleEndTime : '18:00:00'
    if (!survey || !survey.scheduleDayOfWeek) {
      return <div>Loading...</div>
    }

    return (
      <div className='col s12 m7 offset-m1'>
        <div className='row'>
          <div className='col s12'>
            <h4>Set up a schedule</h4>
            <p className='flow-text'>
              The schedule of your survey restricts the days and hours during which respondents will be contacted. You can also specify re-contact attempts intervals.
            </p>
          </div>
        </div>
        <div className='row'>
          {days.map((day) => (
            <div className='col s1' key={day}>
              <button type='button' className={`btn-floating btn-flat btn-large waves-effect waves-light ${survey.scheduleDayOfWeek[day] ? 'green white-text' : 'grey lighten-3 grey-text text-darken-1'}`} onClick={() =>
                this.toggleDay(day)
              }>
                {day}
              </button>
            </div>
          ))}
        </div>
        <div className='row'>
          <div className='input-field col s3'>
            <Input type='select' label='From' defaultValue={defaultFrom} onChange={(value) => this.updateFrom(value)}>
              {hours.map((hour) => (
                <option value={hour.value} key={hour.value}>{hour.label}</option>
              ))}
            </Input>
          </div>
          <div className='input-field col s3'>
            <Input type='select' label='To' defaultValue={defaultTo} onChange={(value) => this.updateTo(value)}>
              {hours.map((hour) => (
                <option value={hour.value} key={hour.value}>{hour.label}</option>
              ))}
            </Input>
          </div>
        </div>
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  surveyId: ownProps.params.surveyId,
  survey: state.surveys[ownProps.params.surveyId],
  days: ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'],
  hours: [{label: '12:00 AM', value: '00:00:00'}, {label: '01:00 AM', value: '01:00:00'},
          {label: '02:00 AM', value: '02:00:00'}, {label: '03:00 AM', value: '03:00:00'},
          {label: '04:00 AM', value: '04:00:00'}, {label: '05:00 AM', value: '05:00:00'},
          {label: '06:00 AM', value: '06:00:00'}, {label: '07:00 AM', value: '07:00:00'},
          {label: '08:00 AM', value: '08:00:00'}, {label: '09:00 AM', value: '09:00:00'},
          {label: '10:00 AM', value: '10:00:00'}, {label: '11:00 AM', value: '11:00:00'},
          {label: '12:00 PM', value: '12:00:00'}, {label: '01:00 PM', value: '13:00:00'},
          {label: '02:00 PM', value: '14:00:00'}, {label: '03:00 PM', value: '15:00:00'},
          {label: '04:00 PM', value: '16:00:00'}, {label: '05:00 PM', value: '17:00:00'},
          {label: '06:00 PM', value: '18:00:00'}, {label: '07:00 PM', value: '19:00:00'},
          {label: '08:00 PM', value: '20:00:00'}, {label: '09:00 PM', value: '21:00:00'},
          {label: '10:00 PM', value: '22:00:00'}, {label: '11:00 PM', value: '23:00:00'}]})

export default withRouter(connect(mapStateToProps)(SurveyWizardScheduleStep))
