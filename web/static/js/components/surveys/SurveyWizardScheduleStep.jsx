import * as actions from '../../actions/survey'
import * as uiActions from '../../actions/ui'
import { connect } from 'react-redux'
import React, { PropTypes, Component } from 'react'
import { TimeDropdown, DatePicker, dayLabel, Card } from '../ui'
import SurveyWizardRetryAttempts from './SurveyWizardRetryAttempts'
import { translate } from 'react-i18next'
import TimezoneAutocomplete from '../timezones/TimezoneAutocomplete'
import InfiniteCalendar from 'react-infinite-calendar'
import { isEqual } from 'lodash'
import dateformat from 'dateformat'

class SurveyWizardScheduleStep extends Component {
  static propTypes = {
    t: PropTypes.func,
    survey: PropTypes.object.isRequired,
    dispatch: PropTypes.func.isRequired,
    readOnly: PropTypes.bool.isRequired,
    ui: PropTypes.object.isRequired
  }

  constructor(props) {
    super(props)
    this.updateTimezone = this.updateTimezone.bind(this)
    this.removeBlockedDay = this.removeBlockedDay.bind(this)
    this.addBlockedDay = this.addBlockedDay.bind(this)
    this.updateFrom = this.updateFrom.bind(this)
    this.updateTo = this.updateTo.bind(this)
    this.toggleBlockedDays = this.toggleBlockedDays.bind(this)
    this.state = {
      showStartDatePicker: false
    }
  }

  toggleStartDatePicker(event: any) {
    this.setState({
      showStartDatePicker: !this.state.showStartDatePicker
    })
    event.preventDefault()
  }

  updateFrom(event) {
    const { dispatch } = this.props
    const next = event.target.options[event.target.selectedIndex + 1] ? event.target.options[event.target.selectedIndex + 1].value : '23:59:59'
    dispatch(actions.setScheduleFrom(event.target.value, next))
  }

  updateTo(event) {
    const { dispatch } = this.props
    const previous = event.target.selectedIndex != 0 ? event.target.options[event.target.selectedIndex - 1].value : '00:00:00'
    dispatch(actions.setScheduleTo(event.target.value, previous))
  }

  updateTimezone(event) {
    const { dispatch } = this.props
    dispatch(actions.setTimezone(event.target.value))
  }

  removeBlockedDay(day) {
    const { dispatch } = this.props
    dispatch(actions.removeScheduleBlockedDay(day))
  }

  addBlockedDay(day) {
    const { dispatch } = this.props
    dispatch(actions.addScheduleBlockedDay(day))
  }

  toggleBlockedDays() {
    const { dispatch } = this.props
    dispatch(uiActions.toggleBlockedDays())
    dispatch(actions.clearBlockedDays())
  }

  toggleDay(day) {
    const { dispatch } = this.props
    dispatch(actions.toggleDay(day))
  }

  dateFromString(date: string) {
    const splitted = date.split('-')
    return new Date(parseInt(splitted[0]), parseInt(splitted[1]) - 1, parseInt(splitted[2]))
  }

  formatDate(date: string) {
    return dateformat(this.dateFromString(date), 'mmm dd, yyyy')
  }

  render() {
    const { survey, readOnly, ui, t, dispatch } = this.props
    const days = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat']

    // Survey might be loaded without details
    let defaultFrom = (survey && survey.schedule && survey.schedule.startTime) ? survey.schedule.startTime : '09:00:00'
    let defaultTo = (survey && survey.schedule && survey.schedule.endTime) ? survey.schedule.endTime : '18:00:00'

    if (!survey || !survey.schedule || !survey.schedule.dayOfWeek) {
      return <div>{t('Loading...')}</div>
    }

    const { startDate } = survey.schedule

    return (
      <div>
        <div className='row'>
          <div className='col s12'>
            <h4>{t('Setup a schedule')}</h4>
            <p className='flow-text'>
              {t('The schedule of your survey restricts the days and hours during which respondents will be contacted. You can also specify re-contact attempts intervals.')}
            </p>
          </div>
        </div>
        <div className='row'>
          {days.map((day) => (
            <div className='col' key={day}>
              <button type='button'
                className={`btn-floating btn-flat btn-large waves-effect waves-light ${survey.schedule.dayOfWeek[day] ? 'green white-text' : 'grey lighten-3 grey-text text-darken-1'}`}
                onClick={() => readOnly ? null : this.toggleDay(day)}>
                {dayLabel(day)}
              </button>
            </div>
          ))}
        </div>
        <div className='row'>
          <TimeDropdown label={t('From')} defaultValue={defaultFrom} onChange={this.updateFrom} readOnly={readOnly} min={null} extraOption={{ at: 0, item: { label: '12:00 AM', value: '00:00:00' } }} />
          <TimeDropdown label={t('To')} defaultValue={defaultTo} onChange={this.updateTo} readOnly={readOnly} min={defaultFrom} extraOption={{ at: 23, item: { label: '12:00 AM', value: '23:59:59' } }} />
        </div>
        <div className='row'>
          <div className='col s12'>
            <label className='grey-text'>{this.props.t('Start date')}</label>
            <input
              type='text'
              value={(startDate && this.formatDate(startDate)) || ''}
              disabled={readOnly}
            />
            <div className='right datepicker start-date'>
              {
                readOnly
                ? <i disabled className='material-icons'>today</i>
                : <a className='black-text' href='#' onClick={event => { this.toggleStartDatePicker(event) }}><i className='material-icons'>today</i></a>
              }
              {
                this.state.showStartDatePicker
                  ? <Card className='datepicker-card'>
                    <InfiniteCalendar selected={startDate} onSelect={date => {
                      const formattedDate = dateformat(date, 'yyyy-mm-dd')
                      const selectedDate = isEqual(formattedDate, startDate)
                      ? null
                      : formattedDate
                      dispatch(actions.selectScheduleStartDate(selectedDate))
                    }} />
                  </Card>
                : null
              }
            </div>
          </div>
        </div>
        <div className='row'>
          <div className='col s12'>
            <div className='input-field'>
              <input
                id='block-dates'
                type='checkbox'
                checked={ui.allowBlockedDays}
                disabled={readOnly}
                className='filled-in'
                onChange={this.toggleBlockedDays}
              />
              <label htmlFor='block-dates'>{t('Block dates')}</label>
            </div>
          </div>
        </div>
        { ui.allowBlockedDays
          ? <div className='row'>
            <div className='col s12'>
              <DatePicker removeDate={this.removeBlockedDay} addDate={this.addBlockedDay} dates={survey.schedule.blockedDays} readOnly={readOnly} />
            </div>
          </div>
          : ''
        }
        <div className='row'>
          <div className='col s12 m6'>
            <TimezoneAutocomplete selectedTz={survey.schedule.timezone} readOnly={readOnly} />
          </div>
        </div>
        <SurveyWizardRetryAttempts readOnly={readOnly} />
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  timezones: state.timezones,
  ui: state.ui.data.surveyWizard
})

export default translate()(connect(mapStateToProps)(SurveyWizardScheduleStep))
