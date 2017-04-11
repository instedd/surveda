import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import * as actions from '../../actions/survey'
import { QuotasModal } from './QuotasModal'
import { InputWithLabel } from '../ui'
import find from 'lodash/find'
import join from 'lodash/join'
import { stepStoreValues } from '../../reducers/questionnaire'

class SurveyWizardCutoffStep extends Component {
  static propTypes = {
    survey: PropTypes.object.isRequired,
    questionnaire: PropTypes.object,
    dispatch: PropTypes.func.isRequired,
    readOnly: PropTypes.bool.isRequired
  }

  constructor(props) {
    super(props)
    this.state = {
      buckets: {}
    }
    this.toggleCountPartialResults = this.toggleCountPartialResults.bind(this)
  }

  cutoffChange(e) {
    e.preventDefault()
    const { dispatch } = this.props
    var onlyNumbers = e.target.value.replace(/[^0-9.]/g, '')

    if (onlyNumbers == e.target.value && onlyNumbers < Math.pow(2, 31) - 1) {
      dispatch(actions.changeCutoff(onlyNumbers))
    }
  }

  quotaChange(e) {
    e.preventDefault()
    const { dispatch, survey } = this.props
    var onlyNumbers = e.target.value.replace(/[^0-9.]/g, '')

    if (onlyNumbers == e.target.value && onlyNumbers < Math.pow(2, 31) - 1) {
      const condition = find(survey.quotas.buckets, (bucket) =>
        this.bucketLabel(bucket) == e.target.id
      ).condition
      dispatch(actions.quotaChange(condition, onlyNumbers))
    }
  }

  setQuotaVars(storeVars) {
    const { dispatch, questionnaire } = this.props
    dispatch(actions.setQuotaVars(storeVars, questionnaire))
  }

  bucketLabel(bucket) {
    return join(bucket.condition.map(({store, value}) => {
      if ((typeof value) == 'object') {
        value = join(value, ' - ')
      }
      return `${store}: ${value}`
    }), ', ')
  }

  turnOnQuotas() {
    const { survey } = this.props
    if (survey.quotas.vars.length == 0) {
      $('#setupQuotas').modal('open')
    }
  }

  turnOffQuotas() {
    const { dispatch, questionnaire, survey } = this.props
    if (survey.quotas.vars.length != 0) {
      dispatch(actions.setQuotaVars([], questionnaire))
    }
  }

  toggleCountPartialResults() {
    const { dispatch } = this.props
    dispatch(actions.toggleCountPartialResults())
  }

  header() {
    return (
      <div className='row'>
        <div className='col s12'>
          <h4>Configure cutoff rules</h4>
          <p className='flow-text'>
            Cutoff rules define when the survey will stop. You can use one or more of these options. If you don't select any, the survey will be sent to all respondents.
          </p>
        </div>
      </div>
    )
  }

  renderWithQuotas() {
    const { questionnaire, survey, readOnly } = this.props
    const hasQuotas = questionnaire && survey.quotas.vars.length > 0

    let quotasModal = null
    if (!readOnly) {
      quotasModal = (
        <div className='row'>
          <div className='col s12'>
            <QuotasModal showLink={hasQuotas} modalId='setupQuotas' linkText='EDIT QUOTAS' header='Quotas' confirmationText='DONE' showCancel onConfirm={vars => this.setQuotaVars(vars)} questionnaire={questionnaire} survey={survey} />
          </div>
        </div>
      )
    }

    let quotasForCompletes = (
      <div>
        <div className='row quotas'>
          <div className='col s12'>
            <input type='radio' className='filled-in with-gap' id='set-quotas' checked={hasQuotas} onChange={() => this.turnOnQuotas()} disabled={readOnly} />
            <label htmlFor='set-quotas'>Quotas for completes</label>
            <p className='grey-text'>Quotas allow you to define minimum number of completed results for specific categories such as age or gender.</p>
          </div>
        </div>
        {quotasModal}
      </div>
    )

    const partialsInput = (
      <input
        id='toggle_count_partial_results'
        type='checkbox'
        checked={survey.countPartialResults}
        disabled={readOnly}
        className='filled-in'
        onChange={this.toggleCountPartialResults}
      />
    )
    const partialsLabel = <label className='bottom-margin' htmlFor='toggle_count_partial_results'>Count partials as completed</label>

    let partialsForCutoff = null
    let partialsForQuotas = null
    if (hasQuotas) {
      partialsForQuotas = (
        <div className='row'>
          <div className='col s12'>
            {partialsInput}
            {partialsLabel}
          </div>
        </div>
      )
    } else {
      partialsForCutoff = (
        <div className='col s12'>
          {partialsInput}
          {partialsLabel}
        </div>
      )
    }

    return (
      <div>
        {this.header()}
        <div className='row'>
          <div className='col s12'>
            <input type='radio' className='with-gap' id='survey_cutoff' checked={!hasQuotas} onChange={() => this.turnOffQuotas()} disabled={readOnly} />
            <label htmlFor='survey_cutoff'>Number of completes</label>
            <div className='input-field inline'>
              <InputWithLabel id='completed-results' value={survey.cutoff || ''} label='' >
                <input
                  type='text'
                  onChange={e => this.cutoffChange(e)}
                  disabled={readOnly || hasQuotas}
                />
              </InputWithLabel>
            </div>
          </div>
          {partialsForCutoff}
        </div>
        {quotasForCompletes}
        { survey.quotas.buckets
          ? survey.quotas.buckets.map((bucket, index) =>
            <div className='row quotas' key={index} >
              <div className='col s12'>
                <InputWithLabel value={bucket.quota == null ? 0 : bucket.quota} id={this.bucketLabel(bucket)} label={this.bucketLabel(bucket)} >
                  <input
                    type='text'
                    onChange={e => this.quotaChange(e)}
                    disabled={readOnly}
                  />
                </InputWithLabel>
              </div>
            </div>
          )
          : ''
        }
        {partialsForQuotas}
      </div>
    )
  }

  renderWithoutQuotas() {
    const { survey, readOnly } = this.props

    return (
      <div>
        {this.header()}
        <div className='row'>
          <div className='col s12'>
            Number of completes
            <div className='input-field inline'>
              <InputWithLabel id='completed-results' value={survey.cutoff || ''} label='' >
                <input
                  type='text'
                  onChange={e => this.cutoffChange(e)}
                  disabled={readOnly}
                />
              </InputWithLabel>
            </div>
          </div>
          <div className='col s12'>
            <div className='input-field'>
              <input
                id='toggle_count_partial_results'
                type='checkbox'
                checked={survey.countPartialResults}
                disabled={readOnly}
                className='filled-in'
                onChange={this.toggleCountPartialResults}
              />
              <label htmlFor='toggle_count_partial_results'>Count partials as completed</label>
            </div>
          </div>
        </div>
      </div>
    )
  }

  render() {
    const { questionnaire } = this.props
    const hasQuotas = questionnaire && Object.keys(stepStoreValues(questionnaire)).length
    if (hasQuotas) {
      return this.renderWithQuotas()
    } else {
      return this.renderWithoutQuotas()
    }
  }
}

export default connect()(SurveyWizardCutoffStep)
