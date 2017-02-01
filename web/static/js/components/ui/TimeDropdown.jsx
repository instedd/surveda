import React, { PropTypes, PureComponent } from 'react'
import { Input } from 'react-materialize'

class TimeDropdown extends PureComponent {
  static propTypes = {
    defaultValue: PropTypes.any,
    onChange: PropTypes.func,
    label: PropTypes.string,
    readOnly: PropTypes.bool
  }

  render() {
    const { defaultValue, onChange, label, readOnly } = this.props
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

    return (
      <Input s={12} m={3} type='select' label={label} defaultValue={defaultValue} onChange={onChange} disabled={readOnly}>
        {hours.map((hour) => (
          <option value={hour.value} key={hour.value}>{hour.label}</option>
        ))}
      </Input>
    )
  }
}

export default TimeDropdown
