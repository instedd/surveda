import { connect } from 'react-redux'
import React, { PropTypes, Component } from 'react'
import * as actions from '../../actions/survey'
import { InputWithLabel } from '../ui'

class SurveyWizardRetryAttempts extends Component {
  componentDidMount() {
    const { survey } = this.props
    if (survey.data) {
      this.setState({smsRetryConfiguration: survey.data.smsRetryConfiguration, ivrRetryConfiguration: survey.data.ivrRetryConfiguration})
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
          const invalid = (mode === 'sms') ? !!survey.errors.smsRetryConfiguration : survey.errors.ivrRetryConfiguration
          return (
            <div className='row' key={mode}>
              <div className='input-field col s12'>
                <InputWithLabel id={`recontact-attempts${mode}`} value={defaultValue || ''} label={`${mode == 'sms' ? 'SMS' : 'Phone'} re-contact attempts`} >
                  <input
                    type='text'
                    onChange={e => this.editingRetryConfiguration(mode, e)}
                    onBlur={e => this.retryConfigurationChanged(mode, e)}
                    className={invalid ? 'invalid' : ''}
                    />
                </InputWithLabel>
                <span className='small-text-bellow'>
                  Enter delays like 5m 2h to express time units
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
  survey: PropTypes.object
}

export default connect(mapStateToProps)(SurveyWizardRetryAttempts)
