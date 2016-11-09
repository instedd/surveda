import * as actions from '../../actions/survey'
import { fetchTimezones } from '../../actions/timezones'
import { connect } from 'react-redux'
import { Input } from 'react-materialize'
import React, { PropTypes, Component } from 'react'

class SurveyWizardScheduleStep extends Component {
  static propTypes = {
    survey: PropTypes.object.isRequired,
    dispatch: PropTypes.func.isRequired,
    timezones: PropTypes.object
  }

  updateFrom(event) {
    const { dispatch } = this.props
    dispatch(actions.setScheduleFrom(event.target.value))
  }

  updateTo(event) {
    const { dispatch } = this.props
    dispatch(actions.setScheduleTo(event.target.value))
  }

  updateTimezone(event) {
    const { dispatch } = this.props
    dispatch(actions.setTimezone(event.target.value))
  }

  toggleDay(day) {
    const { dispatch } = this.props
    dispatch(actions.toggleDay(day))
  }

  componentDidMount() {
    const { dispatch } = this.props
    dispatch(fetchTimezones())
  }

  formatTimezone(tz) {
    const split = tz.split('/')
    let res = split[0]
    if (split.length == 2) {
      res = split.join(' - ')
    } else {
      if (split.length == 3) {
        res = res + ' - ' + split[2] + ', ' + split[1]
      }
    }
    return res
  }

  retryConfigurationChanged(mode, e) {
    e.preventDefault(e)
    const { dispatch } = this.props
    const value = e.target.value
    if (mode == 'sms') {
      dispatch(actions.changeSmsRetryConfiguration(value))
    } else {
      if (mode == 'ivr') {
        dispatch(actions.changeIvrRetryConfiguration(value))
      }
    }
  }

  retryConfigurationInfo(survey) {
    const modes = survey.mode
    if (modes) {
      return (
        modes.map((mode) => {
          const defaultValue = (mode === 'sms') ? survey.smsRetryConfiguration : survey.ivrRetryConfiguration
          return (
            <div className='row' key={mode}>
              <div className='input-field col s12'>
                <input
                  id='completed-results'
                  type='text'
                  value={defaultValue || ''}
                  onChange={e => this.retryConfigurationChanged(mode, e)} />
                <label className='active' htmlFor='completed-results'>{mode} re-contact attempts</label>
              </div>
            </div>
          )
        })
      )
    }
  }

  render() {
    const { survey, timezones } = this.props
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
    let defaultTimezone = (survey && survey.timezone) ? survey.timezone : (Intl.DateTimeFormat().resolvedOptions().timeZone)

    if (!survey || !survey.scheduleDayOfWeek) {
      return <div>Loading...</div>
    }

    if (!timezones || !timezones.items) {
      return (
        <div>Loading timezones...</div>
      )
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
            <div className='col' key={day}>
              <button type='button' className={`btn-floating btn-flat btn-large waves-effect waves-light ${survey.scheduleDayOfWeek[day] ? 'green white-text' : 'grey lighten-3 grey-text text-darken-1'}`} onClick={() =>
                this.toggleDay(day)
              }>
                {day}
              </button>
            </div>
          ))}
        </div>
        <div className='row'>
          <Input s={12} m={6} type='select' label='From' defaultValue={defaultFrom} onChange={(value) => this.updateFrom(value)}>
            {hours.map((hour) => (
              <option value={hour.value} key={hour.value}>{hour.label}</option>
            ))}
          </Input>
          <Input s={12} m={6} type='select' label='To' defaultValue={defaultTo} onChange={(value) => this.updateTo(value)}>
            {hours.map((hour) => (
              <option value={hour.value} key={hour.value}>{hour.label}</option>
            ))}
          </Input>
        </div>
        <div className='row'>
          <Input s={12} m={6} type='select' label='Timezones' defaultValue={defaultTimezone} onChange={(value) => this.updateTimezone(value)}>
            {timezones.items.map((tz) => (
              <option value={tz} key={tz}>{this.formatTimezone(tz)}</option>
            ))}
          </Input>
        </div>
        {
          this.retryConfigurationInfo(survey)
        }
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  timezones: state.timezones
})

export default connect(mapStateToProps)(SurveyWizardScheduleStep)
