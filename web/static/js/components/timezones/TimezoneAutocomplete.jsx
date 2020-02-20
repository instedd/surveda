import React, { PropTypes, Component } from 'react'
import { fetchTimezones } from '../../actions/timezones'
import { connect } from 'react-redux'
import { translate } from 'react-i18next'
import { Autocomplete, InputWithLabel } from '../ui'
import * as actions from '../../actions/survey'
import { formatTimezone } from './util'
import 'materialize-autocomplete'

class TimezoneAutocomplete extends Component {
  static propTypes = {
    t: PropTypes.func,
    dispatch: PropTypes.func.isRequired,
    selectedTz: PropTypes.string,
    timezones: PropTypes.object,
    readOnly: PropTypes.bool,
    i18n: PropTypes.object
  }

  constructor(props) {
    super(props)
    this.timeZoneInput = null
    this.state = {
      fetching: false,
      timezone: {
        id: '',
        text: ''
      }
    }
  }

  getTimezoneInputRef = () => {
    return this.timeZoneInput
  }

  componentDidMount() {
    const { dispatch, selectedTz } = this.props
    const timezone = { id: selectedTz, text: formatTimezone(selectedTz) }
    this.setState({ timezone: timezone })
    dispatch(fetchTimezones())
  }

  buildTimezonesforAutoselect(options) {
    return options.map((element) => {
      return { text: formatTimezone(element), id: element }
    }
    )
  }

  editingTimeZoneInput(event) {
    const timezone = {id: event.target.value, text: event.target.value}
    this.setState({
      timezone: timezone
    })
  }

  autocompleteGetData(value, callback) {
    const { timezones } = this.props
    const matches = (value, tz) => { return (tz.indexOf(value) !== -1 || tz.toLowerCase().indexOf(value) !== -1) }
    const matchingOptions = Object.keys(timezones.items).filter((tz) => matches(formatTimezone(value.toLowerCase()), formatTimezone(tz)))
    callback(value, this.buildTimezonesforAutoselect(matchingOptions))
  }

  autocompleteOnSelect(timezone) {
    const { dispatch } = this.props
    this.setState({timezone: timezone})
    dispatch(actions.setTimezone(timezone.id))
  }

  getTimeForTimezone(timezone, locale) {
    var date = new Date()
    return date.toLocaleString(locale, {timeZone: timezone, hour12: false, hour: '2-digit', minute: '2-digit', weekday: 'long'})
  }

  render() {
    const { timezones, t, readOnly, i18n, selectedTz } = this.props
    const currentLanguage = i18n.language

    if (!timezones || !timezones.items) {
      return (
        <div>{t('Loading timezones...')}</div>
      )
    } else {
      const canonicalTz = timezones.items[selectedTz]
      let timeAtSelectedTz
      try {
        timeAtSelectedTz = this.getTimeForTimezone(canonicalTz, currentLanguage)
      } catch (e) {}
      return (
        <div className='input-field timezone-selection'>
          <InputWithLabel value={this.state.timezone.text} label={t('Timezone')}>
            <input type='text' ref={(ref) => { this.timeZoneInput = ref }} id='timeZoneInput' autoComplete='off' className='timezone-input autocomplete'
              onChange={e => this.editingTimeZoneInput(e)}
              disabled={readOnly}
            />
          </InputWithLabel>
          <Autocomplete
            getInput={() => { return this.getTimezoneInputRef() }}
            getData={(value, callback) => this.autocompleteGetData(value, callback)}
            onSelect={(item) => this.autocompleteOnSelect(item)}
            className='timezone-dropdown'
            ref='autocomplete'
          />
          { timeAtSelectedTz &&
            <span className='small-text-bellow'>{t('Time at selected timezone: {{time}}', {time: timeAtSelectedTz})}</span>
          }
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
