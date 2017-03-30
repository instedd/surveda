import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import * as actions from '../../actions/survey'
import every from 'lodash/every'
import some from 'lodash/some'
import isEqual from 'lodash/isEqual'
import { modeLabel } from '../../reducers/survey'

class SurveyWizardModeStep extends Component {
  static propTypes = {
    survey: PropTypes.object.isRequired,
    questionnaires: PropTypes.object,
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

  questionnairesMatchMode(mode, ids, questionnaires) {
    return every(mode, m =>
      ids && every(ids, id =>
        questionnaires[id] && questionnaires[id].modes && questionnaires[id].modes.indexOf(m) != -1))
  }

  input(id, inputType, modeComparison, mode, modes, value) {
    const { survey, questionnaires, readOnly } = this.props
    const questionnaireIds = survey.questionnaireIds
    const match = this.questionnairesMatchMode(modes, questionnaireIds, questionnaires)

    return (
      <p>
        <input
          id={id}
          type={inputType}
          name='questionnaire_mode'
          className={modeComparison ? 'filled-in' : 'with-gap'}
          value={value}
          checked={this.modeIncludes(mode, modes)}
          onChange={e => this.modeChange(e, modes)}
          disabled={readOnly || !match}
          />
        <label htmlFor={id}>{modeLabel(modes)}</label>
      </p>
    )
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
                className='filled-in'
                disabled={readOnly}
                />
              <label htmlFor='questionnaire_mode_comparison'>Run a comparison to contrast performance between different primary and fallback modes combinations (you can set up the allocations later in the comparisons section)</label>
            </p>
            {this.input('questionnaire_mode_ivr', inputType, modeComparison, mode, ['ivr'], 'ivr')}
            {this.input('questionnaire_mode_ivr_sms', inputType, modeComparison, mode, ['ivr', 'sms'], 'ivr_sms')}
            {this.input('questionnaire_mode_sms', inputType, modeComparison, mode, ['sms'], 'sms')}
            {this.input('questionnaire_mode_sms_ivr', inputType, modeComparison, mode, ['sms', 'ivr'], 'sms_ivr')}
          </div>
        </div>
      </div>
    )
  }
}

export default connect()(SurveyWizardModeStep)
