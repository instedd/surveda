import { connect } from 'react-redux'
import React, { PropTypes, Component } from 'react'
import * as actions from '../../actions/survey'

class SurveyWizardRetryAttempts extends Component {
  static propTypes = {
  }

  componentDidMount() {
    const { survey } = this.props
    this.setState({smsRetryConfiguration: survey.data.smsRetryConfiguration, ivrRetryConfiguration: survey.data.ivrRetryConfiguration})
  }

  editingRetryConfiguration(mode, e) {
    const value = e.target.value.replace(/[^0-9hdm\s]/g, '')
    e.target.value = value
    if (mode == "sms") {
      this.setState({smsRetryConfiguration: value})
    } else {
      if (mode == "ivr") {
        this.setState({ivrRetryConfiguration: value})
      }
    }
  }

  replaceTimeUnits(value) {
    let formattedValue = value
    // /^[\s]+$/.test("    ")
    // /\d+[mhd]/
    formattedValue = formattedValue.replace('m', ' minutes')
    formattedValue = formattedValue.replace('h', ' hours')
    formattedValue = formattedValue.replace('d', ' days')
    return formattedValue
  }

  retryConfigurationFlow(mode, retriesValue) {
    if (retriesValue) {
      let values = retriesValue.split(' ')
      values = values.filter((v) => v )
      values = values.filter((v) => /^\d+[mhd]$/.test(v))
      return (
        <ul>
          <li> - Initial contact </li>
          {values.map((v, i) =>
            <li key={mode + v + i}> - {this.replaceTimeUnits(v)}</li>
          )}
        </ul>
      )
    }
  }

  retryConfigurationChanged(mode, e) {
    const { dispatch } = this.props
    e.preventDefault(e)
    if (mode == 'sms') {
      dispatch(actions.changeSmsRetryConfiguration(this.state.smsRetryConfiguration))
    } else {
      if (mode == 'ivr') {
        dispatch(actions.changeIvrRetryConfiguration(this.state.ivrRetryConfiguration))
      }
    }
  }

  render() {
    const { survey } = this.props
    if (!survey || !this.state) {
      return (<div />)
    }
    const modes = survey.data.mode

    if (!modes || modes.length == 0) {
      return null
    } else {
      const modeRetryConfiguration = (
        modes.map((mode) => {
          const defaultValue = (mode === 'sms') ? this.state.smsRetryConfiguration : this.state.ivrRetryConfiguration
          return (
            <div className='row' key={mode}>
              <div className='input-field col s12'>
                <input
                  id='recontact-attempts'
                  type='text'
                  defaultValue={defaultValue}
                  onChange={e => this.editingRetryConfiguration(mode, e)}
                  onBlur={e => this.retryConfigurationChanged(mode, e)}
                  />
                <label className='active' htmlFor='recontact-attempts'>{mode == 'sms' ? 'SMS' : 'Phone'} re-contact attempts</label>
                <div>
                  Enter delays like 5m 2h to express time units
                </div>
                {this.retryConfigurationFlow(mode, defaultValue)}
              </div>
            </div>
          )
        })
      )
      return (
        <div>
          {modeRetryConfiguration}
        </div>
      )
    }
  }
}

const mapStateToProps = (state, ownProps) => ({
  survey: state.survey
})

export default connect(mapStateToProps)(SurveyWizardRetryAttempts)
