// @flow
import { Card } from "../ui"
import InfiniteCalendar from "react-infinite-calendar"
import React, { Component } from "react"
import i18n from "../../i18next"
import { datePickerTheme, datePickerLocales, datePickerDisplayOptions } from "./DatePicker"

type Props = {
  readOnly: boolean,
  selected: String | null,
  onSelect: Function,
}

type State = {
  showDatePicker: boolean,
}

export default class SingleDatePicker extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = {
      showDatePicker: false,
    }
  }

  toggleStartDatePicker() {
    this.setState({
      showDatePicker: !this.state.showDatePicker,
    })
  }

  render() {
    const { readOnly, selected, onSelect } = this.props
    return (
      <div className="right datepicker single-date-picker">
        {readOnly ? (
          <i disabled className="material-icons">
            today
          </i>
        ) : (
          <a
            className="black-text"
            href="#"
            onClick={(event) => {
              this.toggleStartDatePicker()
              event.preventDefault()
            }}
          >
            <i className="material-icons">today</i>
          </a>
        )}
        {this.state.showDatePicker ? (
          <Card className="datepicker-card">
            <InfiniteCalendar
              selected={selected}
              onSelect={(date) => {
                onSelect(date)
                this.toggleStartDatePicker()
              }}
              theme={datePickerTheme}
              displayOptions={datePickerDisplayOptions}
              locale={datePickerLocales[i18n.language]}
              width="100%"
              displayDate={false}
              height={300}
            />
          </Card>
        ) : null}
      </div>
    )
  }
}
