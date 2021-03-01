// @flow
import { Card } from '../ui'
import InfiniteCalendar from 'react-infinite-calendar'
import React, { Component } from 'react'
import i18n from '../../i18next'

type Props = {
  readOnly: boolean,
  selected: String | null,
  onSelect: Function
}

type State = {
  showDatePicker: boolean
}

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
export default class SingleDatePicker extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
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

  toggleStartDatePicker(event: any) {
    this.setState({
      showDatePicker: !this.state.showDatePicker
    })
    event.preventDefault()
  }

  render() {
    const { readOnly, selected, onSelect } = this.props
    return <div className='right datepicker start-date'>
      {
        readOnly
        ? <i disabled className='material-icons'>today</i>
        : <a className='black-text' href='#' onClick={event => { this.toggleStartDatePicker(event) }}><i className='material-icons'>today</i></a>
      }
      {
        this.state.showDatePicker
          ? <Card className='datepicker-card'>
            <InfiniteCalendar selected={selected} onSelect={onSelect}
              theme={{
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
              }}
              displayOptions={{
                showHeader: true,
                showWeekdays: true
              }}
              locale={this.getLocale(i18n.language)}
              width='100%'
              displayDate={false}
              height={300}
             />
          </Card>
        : null
      }
    </div>
  }
}
