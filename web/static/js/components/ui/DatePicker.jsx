// @flow
import React, { Component, PropTypes } from 'react'
import classNames from 'classnames/bind'
import dateformat from 'dateformat'
import includes from 'lodash/includes'
import { Card } from './'
import InfiniteCalendar, { Calendar, defaultMultipleDateInterpolation, withMultipleDates } from 'react-infinite-calendar'
import 'react-infinite-calendar/styles.css'

const MultipleDatesCalendar = withMultipleDates(Calendar)

export class DatePicker extends Component {
  addDate: Function
  toggleDatePicker: Function
  state: Object

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

  removeDate(date: any) {
    return function(e) {
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

  render() {
    const { className, style, dates, readOnly } = this.props
    return (
      <div>
        <div className={classNames(className, {'chips': true})} style={style}>
          { dates
            ? dates.map((date, index) =>
              <div className='chip' key={index}>
                {
                  dateformat(new Date(date), 'mmm dd, yyyy       ')
                }
                {date}
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
            ? <a className='black-text right' href='#' onClick={this.toggleDatePicker}><i className='material-icons'>today</i></a>
            : ''
          }
        </div>
        { this.state.showDatePicker
          ? <div className='datepicker'>
            <Card className='datepicker-card'>
              <InfiniteCalendar
                Component={MultipleDatesCalendar}
                theme={{
                  accentColor: '#4CAF50',
                  floatingNav: {
                    background: 'rgba(245, 245, 245, 0.94)',
                    chevron: '#000',
                    color: '#000'
                  },
                  headerColor: '#4CAF50',
                  selectionColor: '#4CAF50',
                  textColor: {
                    active: '#FFF',
                    default: '#333'
                  },
                  todayColor: '#4CAF50',
                  weekdayColor: '#4CAF50'
                }}
                displayOptions={{
                  layout: 'landscape',
                  showOverlay: false,
                  shouldHeaderAnimate: false,
                  showHeader: false,
                  showWeekdays: false
                }}
                width='100%'
                height={300}
                interpolateSelection={defaultMultipleDateInterpolation}
                selected={dates}
                onSelect={this.addDate}
              />
            </Card>
          </div>
          : ''
        }
      </div>
    )
  }
}

