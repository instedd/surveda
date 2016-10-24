import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import * as actions from '../actions/surveyEdit'

class SurveyWizardCutoffStep extends Component {
  static propTypes = {
    survey: PropTypes.object.isRequired,
    dispatch: PropTypes.func.isRequired
  }

  cutoffChange(e) {
    e.preventDefault()
    const { dispatch } = this.props
    var onlyNumbers = e.target.value.replace(/[^0-9.]/g, '')

    dispatch(actions.changeCutoff(onlyNumbers))
  }

  render() {
    return (
      <div>
        <div className='row'>
          <div className='col s12'>
            <h4>Configure cutoff rules</h4>
            <p className='flow-text'>
              Cutoff rules define when the survey will stop. You can use one or more of these options. If you don't select any, the survey will be sent to all respondents.
            </p>
          </div>
        </div>
        <div className='row'>
          <div className='input-field col s12'>
            <input
              id='completed-results'
              type='text'
              value={this.props.survey.cutoff || ''}
              onChange={e => this.cutoffChange(e)} />
            <label className='active' htmlFor='completed-results'>Completed results</label>
          </div>
        </div>
      </div>
    )
  }
}

export default connect()(SurveyWizardCutoffStep)
