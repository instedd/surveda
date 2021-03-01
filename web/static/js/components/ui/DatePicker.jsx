// @flow
import React, { Component, PropTypes } from 'react'
import classNames from 'classnames/bind'
import dateformat from 'dateformat'
import includes from 'lodash/includes'
import { Card } from './'
import InfiniteCalendar, { Calendar, defaultMultipleDateInterpolation, withMultipleDates } from 'react-infinite-calendar'
import 'react-infinite-calendar/styles.css'

import i18n from '../../i18next'

export const datePickerDisplayOptions = {
  showHeader: true,
  showWeekdays: true
}

export const datePickerTheme = {
  accentColor: '#4CAF50',
  floatingNav: {
    background: 'rgba(245, 245, 245, 0.94)',
    chevron: '#9a9a9a',
    color: '#9a9a9a'
  },
  headerColor: '#FFF',
  selectionColor: '#FFF',
  textColor: {
    active: '#9a9a9a',
    default: '#333'
  },
  todayColor: '#e0e0e0',
  weekdayColor: '#FFF'
}

const MultipleDatesCalendar = withMultipleDates(Calendar)

const enLocale = {
  name: 'en',
  blank: 'Select a date...',
  headerFormat: 'ddd, MMM Do',
  todayLabel: {
    long: 'Today'
  },
  weekdays: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
  weekStartsOn: 0
}

const esLocale = {
  name: 'es',
  blank: 'Elija una fecha...',
  headerFormat: 'ddd, MMM Do',
  locale: require('date-fns/locale/es'),
  todayLabel: {
    long: 'Hoy'
  },
  weekdays: ['Dom', 'Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab'],
  weekStartsOn: 0
}

const frLocale = {
  name: 'fr',
  blank: 'Aucune date sélectionnée',
  headerFormat: 'dddd, D MMM',
  locale: require('date-fns/locale/fr'),
  todayLabel: {
    long: "Aujourd'hui",
    short: 'Auj.'
  },
  weekdays: ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'],
  weekStartsOn: 1
}

export const datePickerLocales = {
  'en': enLocale,
  'es': esLocale,
  'fr': frLocale
}

export class DatePicker extends Component<any, any> {
  addDate: Function
  toggleDatePicker: Function

  static propTypes = {
    readOnly: PropTypes.bool,
    style: PropTypes.object,
    className: PropTypes.string,
    removeDate: PropTypes.func.isRequired,
    addDate: PropTypes.func.isRequired,
    dates: PropTypes.array.isRequired
  }

  constructor(props: any) {
    super(props)
    this.addDate = this.addDate.bind(this)
    this.toggleDatePicker = this.toggleDatePicker.bind(this)
    this.state = {
      showDatePicker: false
    }
  }

  getLocale(locale: string) {
    switch (locale) {
      case 'en':
        return enLocale
      case 'fr':
        return frLocale
      case 'es':
        return esLocale
    }
  }

  removeDate(date: any) {
    return function(e: Event) {
      this.props.removeDate(date)
      e.preventDefault()
    }.bind(this)
  }

  addDate(date: Date, isSelected: boolean, selectedDates: Date[]) {
    if (includes(this.props.dates, dateformat(date, 'yyyy-mm-dd'))) {
      this.props.removeDate(dateformat(date, 'yyyy-mm-dd'))
    } else {
      this.props.addDate(dateformat(date, 'yyyy-mm-dd'))
    }
  }

  toggleDatePicker(e: any) {
    this.setState({
      showDatePicker: !this.state.showDatePicker
    })
    e.preventDefault()
  }

  dateFromString(date: string) {
    const splitted = date.split('-')
    return new Date(parseInt(splitted[0]), parseInt(splitted[1]) - 1, parseInt(splitted[2]))
  }

  formatDate(date: string) {
    return dateformat(this.dateFromString(date), 'mmm dd, yyyy')
  }

  render() {
    const { className, style, dates, readOnly } = this.props
    return (
      <div>
        <div className={classNames(className, {'chips': true})} style={style}>
          { dates
            ? dates.map((date, index) =>
              <div className='chip' key={index}>
                { this.formatDate(date) }
                {
                  !readOnly
                  ? <i className='cross material-icons' onClick={this.removeDate(date)}>close</i>
                  : ''
                }
              </div>
            )
            : ''
          }
          {
            !readOnly
            ? <span className='right datepicker multi-date-picker'>
              <a className='black-text' href='#' onClick={this.toggleDatePicker}><i className='material-icons'>today</i></a>
              { this.state.showDatePicker
                ? <Card className='datepicker-card'>
                  <InfiniteCalendar
                    Component={MultipleDatesCalendar}
                    theme={datePickerTheme}
                    displayOptions={datePickerDisplayOptions}
                    locale={datePickerLocales[i18n.language]}
                    width='100%'
                    displayDate={false}
                    height={300}
                    interpolateSelection={defaultMultipleDateInterpolation}
                    selected={dates}
                    onSelect={this.addDate}
                  />
                </Card>
                : ''
              }
            </span>
            : ''
          }
        </div>
      </div>
    )
  }
}
