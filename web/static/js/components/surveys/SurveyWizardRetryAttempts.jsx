import { connect } from 'react-redux'
import React, { PropTypes, Component } from 'react'
import * as actions from '../../actions/survey'
import { InputWithLabel, iconFor } from '../ui'
import flatten from 'lodash/flatten'
import uniq from 'lodash/uniq'
import some from 'lodash/some'
import { translate } from 'react-i18next'

class SurveyWizardRetryAttempts extends Component {
  componentDidMount() {
    const { survey } = this.props
    if (survey.data) {
      this.setState({
        smsRetryConfiguration: survey.data.smsRetryConfiguration,
        ivrRetryConfiguration: survey.data.ivrRetryConfiguration,
        mobilewebRetryConfiguration: survey.data.mobilewebRetryConfiguration,
        fallbackDelay: survey.data.fallbackDelay
      })
    }
  }

  retryConfigurationChanged(mode, e) {
    const { dispatch, t } = this.props
    const value = e.target.value
    switch (mode) {
      case 'sms':
        this.setState({smsRetryConfiguration: value})
        dispatch(actions.changeSmsRetryConfiguration(value))
        break
      case 'ivr':
        this.setState({ivrRetryConfiguration: value})
        dispatch(actions.changeIvrRetryConfiguration(value))
        break
      case 'mobileweb':
        this.setState({mobilewebRetryConfiguration: value})
        dispatch(actions.changeMobileWebRetryConfiguration(value))
        break
      case 'fallbackDelay':
        this.setState({fallbackDelay: value})
        dispatch(actions.changeFallbackDelay(value))
        break
      default:
        throw new Error(t('Unknown mode: {{mode}}', {mode}))
    }
  }

  replaceTimeUnits(value) {
    const { t } = this.props

    let match = /^(\d+)(.)$/.exec(value)
    if (match) {
      let count = parseInt(match[1])

      switch (match[2]) {
        case 'm':
          return t('{{count}} minute', {count})
        case 'd':
          return t('{{count}} day', {count})
        case 'h':
          return t('{{count}} hour', {count})
      }
    }

    return value
  }

  retryConfigurationFlow(mode, retriesValue) {
    const { t } = this.props
    if (retriesValue) {
      let values = retriesValue.split(' ')
      values = values.filter((v) => v)
      values = values.filter((v) => /^\d+[mhd]$/.test(v))
      let cssClass
      switch (mode) {
        case 'sms':
          cssClass = 'sms-attempts'
          break
        case 'ivr':
          cssClass = 'ivr-attempts'
          break
        case 'mobileweb':
          cssClass = 'mobileweb-attempts'
          break
        default:
          throw new Error(t('Unknown mode: {{mode}}', {mode}))
      }
      return (
        <ul className={cssClass}>
          <li className='black-text'>{iconFor(mode)}{t('Initial contact')}</li>
          {values.map((v, i) =>
            <li key={mode + v + i}><span>{this.replaceTimeUnits(v)}</span></li>
          )}
        </ul>
      )
    }
  }

  defaultValue(mode) {
    const { t } = this.props
    switch (mode) {
      case 'sms':
        return this.state.smsRetryConfiguration
      case 'ivr':
        return this.state.ivrRetryConfiguration
      case 'mobileweb':
        return this.state.mobilewebRetryConfiguration
      case 'fallbackDelay':
        return this.state.fallbackDelay
      default:
        throw new Error(t('Unknown mode: {{mode}}', {mode}))
    }
  }

  invalid(mode, errors) {
    const { t } = this.props
    switch (mode) {
      case 'sms':
        return !!errors.smsRetryConfiguration
      case 'ivr':
        return !!errors.ivrRetryConfiguration
      case 'mobileweb':
        return !!errors.mobilewebRetryConfiguration
      case 'fallbackDelay':
        return !!errors.fallbackDelay
      default:
        throw new Error(t('Unknown mode: {{mode}}', {mode}))
    }
  }

  label(mode) {
    const { t } = this.props
    if (mode == 'sms') {
      return t('SMS re-contact attempts')
    }

    if (mode == 'ivr') {
      return t('Phone re-contact attempts')
    }

    if (mode == 'mobileweb') {
      return t('Mobile Web re-contact attempts')
    }

    throw new Error(t('Unknown mode: {{mode}}', {mode}))
  }

  render() {
    const { survey, readOnly, t } = this.props
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
      modes = uniq(flatten(modes))

      let fallbackDelayComponent = null
      if (hasFallbackMode) {
        const defaultValue = this.defaultValue('fallbackDelay')
        const invalid = this.invalid('fallbackDelay', survey.errorsByPath)
        fallbackDelayComponent = (
          <div className='row'>
            <div className='input-field col s12'>
              <InputWithLabel value={defaultValue || ''} label={t('Fallback delay')}>
                <input
                  type='text'
                  onChange={e => this.retryConfigurationChanged('fallbackDelay', e)}
                  className={invalid ? 'invalid' : ''}
                  disabled={readOnly}
                />
              </InputWithLabel>
              <span className='small-text-bellow'>
                {t('Enter a delay like 10m, 3h or 1d to express a time unit (default 1h, use values greater than 10m)')}
              </span>
            </div>
          </div>
        )
      }

      const modeRetryConfiguration = (
        modes.map((mode) => {
          const defaultValue = this.defaultValue(mode)
          const invalid = this.invalid(mode, survey.errorsByPath)
          return (
            <div className='row' key={mode}>
              <div className='input-field col s12'>
                <InputWithLabel id={`recontact-attempts${mode}`} value={defaultValue || ''} label={this.label(mode)} >
                  <input
                    type='text'
                    onChange={e => this.retryConfigurationChanged(mode, e)}
                    className={invalid ? 'invalid' : ''}
                    disabled={readOnly}
                    />
                </InputWithLabel>
                <span className='small-text-bellow'>
                  {t('Enter delays like 10m 2h 1d to express time units (use values greater than 10m)')}
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
  t: PropTypes.func,
  dispatch: PropTypes.func.isRequired,
  survey: PropTypes.object,
  readOnly: PropTypes.bool
}

export default translate()(connect(mapStateToProps)(SurveyWizardRetryAttempts))
