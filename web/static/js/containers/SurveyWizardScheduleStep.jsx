import * as actions from '../actions/surveyEdit'
import { connect } from 'react-redux'
import { Input } from 'react-materialize'
import React, { PropTypes, Component } from 'react'

class SurveyWizardScheduleStep extends Component {
  static propTypes = {
    survey: PropTypes.object.isRequired,
    dispatch: PropTypes.func.isRequired
  }

  updateFrom(event) {
    const { dispatch } = this.props
    dispatch(actions.setScheduleFrom(event.target.value))
  }

  updateTo(event) {
    const { dispatch } = this.props
    dispatch(actions.setScheduleTo(event.target.value))
  }

  toggleDay(day) {
    const { dispatch } = this.props
    dispatch(actions.toggleDay(day))
  }

  render() {
    const { survey } = this.props
    const days = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat']
    const hours = [
      {label: '12:00 AM', value: '00:00:00'}, {label: '01:00 AM', value: '01:00:00'},
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
      {label: '10:00 PM', value: '22:00:00'}, {label: '11:00 PM', value: '23:00:00'}
    ]

    // Survey might be loaded without details
    let defaultFrom = (survey && survey.scheduleStartTime) ? survey.scheduleStartTime : '09:00:00'
    let defaultTo = (survey && survey.scheduleEndTime) ? survey.scheduleEndTime : '18:00:00'
    if (!survey || !survey.scheduleDayOfWeek) {
      return <div>Loading...</div>
    }

    return (
      <div>
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

export default connect()(SurveyWizardScheduleStep)
