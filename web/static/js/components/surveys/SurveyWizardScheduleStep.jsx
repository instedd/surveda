import * as actions from '../../actions/survey'
import { connect } from 'react-redux'
import React, { PropTypes, Component } from 'react'
import TimezoneDropdown from '../timezones/TimezoneDropdown'
import TimeDropdown from '../ui/TimeDropdown'

class SurveyWizardScheduleStep extends Component {
  static propTypes = {
    survey: PropTypes.object.isRequired,
    dispatch: PropTypes.func.isRequired
  }

  constructor(props) {
    super(props)
    this.updateTimezone = this.updateTimezone.bind(this)
    this.updateFrom = this.updateFrom.bind(this)
    this.updateTo = this.updateTo.bind(this)
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

  replaceTimeUnits(value) {
    let formattedValue = value
    formattedValue = formattedValue.replace('m', ' minutes')
    formattedValue = formattedValue.replace('h', ' hours')
    formattedValue = formattedValue.replace('d', ' days')
    return formattedValue
  }

  retryConfigurationChanged(mode, e) {
    e.preventDefault(e)
    const { dispatch } = this.props
    const value = e.target.value.replace(/[^0-9hdm\s]/g, '').trim()
    e.target.value = value
    if (mode == 'sms') {
      dispatch(actions.changeSmsRetryConfiguration(value))
    } else {
      if (mode == 'ivr') {
        dispatch(actions.changeIvrRetryConfiguration(value))
      }
    }
  }

  retryConfigurationFlow(mode, retriesValue) {
    if (retriesValue) {
      const values = retriesValue.split(' ')
      return (
        <ul className='sms-attempts'>
          <li className='black-text'><i className='material-icons v-middle '>phone</i>first contact </li>
          {values.map((v, i) =>
            <li key={mode + v + i}><span>{this.replaceTimeUnits(v)}</span></li>
          )}
        </ul>
      )
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
                  id='recontact-attempts'
                  type='text'
                  defaultValue={defaultValue}
                  onBlur={e => this.retryConfigurationChanged(mode, e)}
                  />
                <label className='active' htmlFor='recontact-attempts'>{mode == 'sms' ? 'SMS' : 'Phone'} re-contact attempts</label>
                <span className='small-text-bellow'>
                  Enter delays like 5m 2h to express time units
                </span>
                {this.retryConfigurationFlow(mode, defaultValue)}
              </div>
            </div>
          )
        })
      )
    }
  }

  render() {
    const { survey } = this.props
    const days = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat']

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
          <TimeDropdown label='From' defaultValue={defaultFrom} onChange={this.updateFrom} />
          <TimeDropdown label='To' defaultValue={defaultTo} onChange={this.updateTo} />
        </div>
        <div className='row'>
          <TimezoneDropdown selectedTz={survey && survey.timezone} onChange={this.updateTimezone} />
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
