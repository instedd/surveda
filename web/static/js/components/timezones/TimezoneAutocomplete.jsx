import React, { PropTypes, Component } from 'react'
import { fetchTimezones } from '../../actions/timezones'
import { connect } from 'react-redux'
import { translate } from 'react-i18next'
import { Autocomplete } from '../ui'
import * as actions from '../../actions/survey'
import { formatTimezone } from './util'
import 'materialize-autocomplete'

class TimezoneAutocomplete extends Component {
  static propTypes = {
    t: PropTypes.func,
    dispatch: PropTypes.func.isRequired,
    selectedTz: PropTypes.string,
    timezones: PropTypes.object
  }

  constructor(props) {
    super(props)
    this.timeZoneInput = null
    this.state = {
      fetching: false
    }
  }

  setTimezoneInputVal = (timezone) => {
    if (this.timeZoneInput) this.timeZoneInput.value = timezone
  }

  focusTimezoneInput = () => {
    if (this.timeZoneInput) this.timeZoneInput.focus()
  }

  getTimezoneInputRef = () => {
    return this.timeZoneInput
  }

  componentDidUpdate() {
    const { selectedTz } = this.props
    this.focusTimezoneInput()
    this.setTimezoneInputVal(formatTimezone(selectedTz))
  }

  componentDidMount() {
    const { dispatch, selectedTz } = this.props
    dispatch(actions.setTimezone(selectedTz))
    this.focusTimezoneInput()
    this.setTimezoneInputVal(formatTimezone(selectedTz))
    dispatch(fetchTimezones())
  }

  buildTimezonesforAutoselect(options) {
    return options.map((element) => {
      return { text: element, id: element }
    }
    )
  }

  autocompleteGetData(value, callback) {
    const { timezones } = this.props
    const matches = (value, tz) => { return (tz.indexOf(value) !== -1 || tz.toLowerCase().indexOf(value) !== -1) }
    const matchingOptions = timezones.items.filter((tz) => matches(value.toLowerCase(), tz))
    callback(value, this.buildTimezonesforAutoselect(matchingOptions))
  }

  autocompleteOnSelect(timezone) {
    const { dispatch } = this.props
    dispatch(actions.setTimezone(timezone.text))
    this.setTimezoneInputVal(formatTimezone(timezone.text))
  }

  render() {
    const { timezones, t } = this.props

    if (!timezones || !timezones.items) {
      return (
        <div>{t('Loading timezones...')}</div>
      )
    } else {
      return (
        <div className='input-field timezone-selection'>
          <label htmlFor='timeZoneInput' className='label'>{ t('Timezone') }</label>
          <input type='text' ref={(ref) => { this.timeZoneInput = ref }} id='timeZoneInput' autoComplete='off' className='timezone-input autocomplete' />
          <Autocomplete
            getInput={() => { return this.getTimezoneInputRef() }}
            getData={(value, callback) => this.autocompleteGetData(value, callback)}
            onSelect={(item) => this.autocompleteOnSelect(item)}
            className='timezone-dropdown'
            ref='autocomplete'
          />
        </div>
      )
    }
  }
}

const mapStateToProps = (state) => {
  return {
    timezones: state.timezones
  }
}

export default translate()(connect(mapStateToProps)(TimezoneAutocomplete))
