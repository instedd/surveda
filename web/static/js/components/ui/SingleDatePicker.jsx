// @flow
import { Card } from '../ui'
import InfiniteCalendar from 'react-infinite-calendar'
import React, { Component } from 'react'

type Props = {
  readOnly: boolean,
  selected: String | null,
  onSelect: Function
}

type State = {
  showDatePicker: boolean
}

export default class SingleDatePicker extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = {
      showDatePicker: false
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
            <InfiniteCalendar selected={selected} onSelect={onSelect} />
          </Card>
        : null
      }
    </div>
  }
}
