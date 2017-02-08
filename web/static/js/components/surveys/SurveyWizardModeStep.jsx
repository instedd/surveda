import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import * as actions from '../../actions/survey'
import some from 'lodash/some'
import isEqual from 'lodash/isEqual'
import { modeLabel } from '../../reducers/survey'

class SurveyWizardModeStep extends Component {
  static propTypes = {
    survey: PropTypes.object.isRequired,
    dispatch: PropTypes.func.isRequired,
    readOnly: PropTypes.bool.isRequired
  }

  modeChange(e, value) {
    const { dispatch } = this.props
    dispatch(actions.selectMode(value))
  }

  modeComparisonChange(e) {
    const { dispatch } = this.props
    dispatch(actions.changeModeComparison())
  }

  modeIncludes(modes, target) {
    return some(modes, ary => isEqual(ary, target))
  }

  render() {
    const { survey, readOnly } = this.props

    if (!survey) {
      return <div>Loading...</div>
    }

    const mode = survey.mode || []
    const modeComparison = mode.length > 1 || (!!survey.modeComparison)

    let inputType = modeComparison ? 'checkbox' : 'radio'

    return (
      <div>
        <div className='row'>
          <div className='col s12'>
            <h4>Select mode</h4>
            <p className='flow-text'>
              Select which modes you want to use.
            </p>
          </div>
        </div>
        <div className='row'>
          <div className='col s12'>
            <p>
              <input
                id='questionnaire_mode_comparison'
                type='checkbox'
                checked={modeComparison}
                onChange={e => this.modeComparisonChange(e)}
                className='with-gap'
                disabled={readOnly}
                />
              <label htmlFor='questionnaire_mode_comparison'>Run a comparison to contrast performance between different primary and fallback modes combinations (you can set up the allocations later in the comparisons section)</label>
            </p>
            <p>
              <input
                id='questionnaire_mode_ivr'
                type={inputType}
                name='questionnaire_mode'
                className='with-gap'
                value='ivr'
                checked={this.modeIncludes(mode, ['ivr'])}
                onChange={e => this.modeChange(e, ['ivr'])}
                disabled={readOnly}
                />
              <label htmlFor='questionnaire_mode_ivr'>{modeLabel(['ivr'])}</label>
            </p>
            <p>
              <input
                id='questionnaire_mode_ivr_sms'
                type={inputType}
                name='questionnaire_mode'
                className='with-gap'
                value='ivr_sms'
                checked={this.modeIncludes(mode, ['ivr', 'sms'])}
                onChange={e => this.modeChange(e, ['ivr', 'sms'])}
                disabled={readOnly}
                />
              <label htmlFor='questionnaire_mode_ivr_sms'>{modeLabel(['ivr', 'sms'])}</label>
            </p>
            <p>
              <input
                id='questionnaire_mode_sms'
                type={inputType}
                name='questionnaire_mode'
                className='with-gap'
                value='sms'
                checked={this.modeIncludes(mode, ['sms'])}
                onChange={e => this.modeChange(e, ['sms'])}
                disabled={readOnly}
                />
              <label htmlFor='questionnaire_mode_sms'>{modeLabel(['sms'])}</label>
            </p>
            <p>
              <input
                id='questionnaire_mode_sms_ivr'
                type={inputType}
                name='questionnaire_mode'
                className='with-gap'
                value='sms_ivr'
                checked={this.modeIncludes(mode, ['sms', 'ivr'])}
                onChange={e => this.modeChange(e, ['sms', 'ivr'])}
                disabled={readOnly}
                />
              <label htmlFor='questionnaire_mode_sms_ivr'>{modeLabel(['sms', 'ivr'])}</label>
            </p>
          </div>
        </div>
      </div>
    )
  }
}

export default connect()(SurveyWizardModeStep)
