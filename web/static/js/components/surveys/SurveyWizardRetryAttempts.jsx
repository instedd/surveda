import { connect } from 'react-redux'
import React, { PropTypes, Component } from 'react'
import * as actions from '../../actions/survey'
import { InputWithLabel } from '../ui'
import flatMap from 'lodash/flatMap'
import uniq from 'lodash/uniq'
import some from 'lodash/some'

class SurveyWizardRetryAttempts extends Component {
  componentDidMount() {
    const { survey } = this.props
    if (survey.data) {
      this.setState({
        smsRetryConfiguration: survey.data.smsRetryConfiguration,
        ivrRetryConfiguration: survey.data.ivrRetryConfiguration,
        fallbackDelay: survey.data.fallbackDelay
      })
    }
  }

  editingRetryConfiguration(mode, e) {
    const value = e.target.value
    switch (mode) {
      case 'sms':
        this.setState({smsRetryConfiguration: value})
        break
      case 'ivr':
        this.setState({ivrRetryConfiguration: value})
        break
      case 'fallbackDelay':
        this.setState({fallbackDelay: value})
        break
      default:
        throw new Error(`unknown mode: ${mode}`)
    }
  }

  replaceTimeUnits(value) {
    let formattedValue = value
    formattedValue = formattedValue.replace('m', ' minutes')
    formattedValue = formattedValue.replace('h', ' hours')
    formattedValue = formattedValue.replace('d', ' days')
    return formattedValue
  }

  retryConfigurationFlow(mode, retriesValue) {
    if (retriesValue) {
      let values = retriesValue.split(' ')
      values = values.filter((v) => v)
      values = values.filter((v) => /^\d+[mhd]$/.test(v))
      let cssClass, icon
      switch (mode) {
        case 'sms':
          cssClass = 'sms-attempts'
          icon = <i className='material-icons v-middle '>sms</i>
          break
        case 'ivr':
          cssClass = 'ivr-attempts'
          icon = <i className='material-icons v-middle '>phone</i>
          break
        default:
          throw new Error(`unknown mode: ${mode}`)
      }
      return (
        <ul className={cssClass}>
          <li className='black-text'>{icon}Initial contact </li>
          {values.map((v, i) =>
            <li key={mode + v + i}><span>{this.replaceTimeUnits(v)}</span></li>
          )}
        </ul>
      )
    }
  }

  retryConfigurationChanged(mode, e) {
    const { dispatch } = this.props
    e.preventDefault(e)
    switch (mode) {
      case 'sms':
        dispatch(actions.changeSmsRetryConfiguration(this.state.smsRetryConfiguration))
        break
      case 'ivr':
        dispatch(actions.changeIvrRetryConfiguration(this.state.ivrRetryConfiguration))
        break
      case 'fallbackDelay':
        dispatch(actions.changeFallbackDelay(this.state.fallbackDelay))
        break
      default:
        throw new Error(`unknown mode: ${mode}`)
    }
  }

  defaultValue(mode) {
    switch (mode) {
      case 'sms':
        return this.state.smsRetryConfiguration
      case 'ivr':
        return this.state.ivrRetryConfiguration
      case 'fallbackDelay':
        return this.state.fallbackDelay
      default:
        throw new Error(`unknown mode: ${mode}`)
    }
  }

  invalid(mode, errors) {
    switch (mode) {
      case 'sms':
        return !!errors.smsRetryConfiguration
      case 'ivr':
        return !!errors.ivrRetryConfiguration
      case 'fallbackDelay':
        return !!errors.fallbackDelay
      default:
        throw new Error(`unknown mode: ${mode}`)
    }
  }

  errorText(mode, errors) {
    switch (mode) {
      case 'sms':
        return errors.smsRetryConfiguration
      case 'ivr':
        return errors.ivrRetryConfiguration
      case 'fallbackDelay':
        return errors.fallbackDelay
      default:
        throw new Error(`unknown mode: ${mode}`)
    }
  }

  render() {
    const { survey, readOnly } = this.props
    if (!survey || !this.state) {
      return (<div />)
    }
    let modes = survey.data.mode

    if (!modes || modes.length == 0) {
      return null
    } else {
      const hasFallbackMode = some(modes, x => x.length > 1)

      // modes will be something like [['sms'], ['sms', 'ivr']]
      // so we convert it to ['sms', 'ivr']
      modes = uniq(flatMap(modes, x => x))

      let fallbackDelayComponent = null
      if (hasFallbackMode) {
        const defaultValue = this.defaultValue('fallbackDelay')
        const invalid = this.invalid('fallbackDelay', survey.errors)
        fallbackDelayComponent = (
          <div className='row'>
            <div className='input-field col s12'>
              <InputWithLabel value={defaultValue || ''} label='Fallback delay'>
                <input
                  type='text'
                  onChange={e => this.editingRetryConfiguration('fallbackDelay', e)}
                  onBlur={e => this.retryConfigurationChanged('fallbackDelay', e)}
                  className={invalid ? 'invalid' : ''}
                  disabled={readOnly}
                />
              </InputWithLabel>
              <span className='small-text-bellow'>
                Enter a delay like 5m, 3h or 1d to express a time unit
              </span>
            </div>
          </div>
        )
      }

      const modeRetryConfiguration = (
        modes.map((mode) => {
          const defaultValue = this.defaultValue(mode)
          const invalid = this.invalid(mode, survey.errors)
          return (
            <div className='row' key={mode}>
              <div className='input-field col s12'>
                <InputWithLabel id={`recontact-attempts${mode}`} value={defaultValue || ''} label={`${mode == 'sms' ? 'SMS' : 'Phone'} re-contact attempts`} >
                  <input
                    type='text'
                    onChange={e => this.editingRetryConfiguration(mode, e)}
                    onBlur={e => this.retryConfigurationChanged(mode, e)}
                    className={invalid ? 'invalid' : ''}
                    disabled={readOnly}
                    />
                </InputWithLabel>
                <span className='small-text-bellow'>
                  Enter delays like 5m 2h 1d to express time units
                </span>
                {this.retryConfigurationFlow(mode, defaultValue)}
              </div>
            </div>
          )
        })
      )
      return (
        <div>
          {modeRetryConfiguration}
          {fallbackDelayComponent}
        </div>
      )
    }
  }
}

const mapStateToProps = (state, ownProps) => ({
  survey: state.survey
})

SurveyWizardRetryAttempts.propTypes = {
  dispatch: PropTypes.func.isRequired,
  survey: PropTypes.object,
  readOnly: PropTypes.bool
}

export default connect(mapStateToProps)(SurveyWizardRetryAttempts)
