import React, { PropTypes, PureComponent } from 'react'
import { fetchTimezones } from '../../actions/timezones'
import { Input } from 'react-materialize'
import { connect } from 'react-redux'

class TimezoneDropdown extends PureComponent {
  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    selectedTz: PropTypes.string,
    timezones: PropTypes.object,
    onChange: PropTypes.func
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

  render() {
    const { timezones, selectedTz, onChange } = this.props

    if (!timezones || !timezones.items) {
      return (
        <div>Loading timezones...</div>
      )
    }

    return (
      <Input s={12} m={6} type='select' label='Timezones' value={selectedTz} onChange={onChange}>
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
