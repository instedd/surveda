import React, { PropTypes, PureComponent } from 'react'
import { fetchTimezones } from '../../actions/timezones'
import { Input } from 'react-materialize'
import { connect } from 'react-redux'

class TimezoneDropdown extends PureComponent {
  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    selectedTz: PropTypes.string,
    timezones: PropTypes.object,
    onChange: PropTypes.func,
    readOnly: PropTypes.bool
  }

  componentDidMount() {
    const { dispatch } = this.props
    dispatch(fetchTimezones())
  }

  formatTimezone(tz) {
    const split = tz.replace('_', ' ').split('/')
    switch (split.length) {
      case 2:
        return `${split[0]} - ${split[1]}`
      case 3:
        return `${split[0]} - ${split[2]}, ${split[1]}`
      default:
        return split[0]
    }
  }

  render() {
    const { timezones, selectedTz, onChange, readOnly } = this.props

    if (!timezones || !timezones.items) {
      return (
        <div>Loading timezones...</div>
      )
    }

    return (
      <Input s={12} m={6} type='select' label='Timezones' value={selectedTz} onChange={onChange} disabled={readOnly}>
        {timezones.items.map((tz) => (
          <option value={tz} key={tz}>{this.formatTimezone(tz)}</option>
        ))}
      </Input>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  timezones: state.timezones
})

export default connect(mapStateToProps)(TimezoneDropdown)
