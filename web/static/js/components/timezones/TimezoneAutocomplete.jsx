import React, { PropTypes, Component } from 'react'
import { fetchTimezones } from '../../actions/timezones'
import { connect } from 'react-redux'
import { translate } from 'react-i18next'
import { Autocomplete } from '../ui'
import * as actions from '../../actions/survey'
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
    this.state = {
      fetching: false
    }
  }

  componentDidMount() {
    const { dispatch, selectedTz } = this.props
    dispatch(actions.setTimezone(selectedTz))
    $(this.refs.timeZoneInput).val(selectedTz)
    $(this.refs.timeZoneInput).focus()
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

  autocompleteOnSelect(event) {
    const { dispatch } = this.props
    dispatch(actions.setTimezone(event.text))
    $(this.refs.timeZoneInput).val(event.text)
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
          <input type='text' ref='timeZoneInput' id='timeZoneInput' autoComplete='off' className='timezone-input autocomplete' />
          <Autocomplete
            getInput={() => this.refs.timeZoneInput}
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
