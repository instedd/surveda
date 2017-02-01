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

  toggleQuotas() {
    const { dispatch, questionnaire, survey } = this.props
    if (survey.quotas.vars.length > 0) {
      dispatch(actions.setQuotaVars([], questionnaire))
    } else {
      $('#setupQuotas').modal('open')
    }
  }

  render() {
    const { questionnaire, survey, readOnly } = this.props

    let quotasForCompletes = null
    if (questionnaire && Object.keys(stepStoreValues(questionnaire)).length) {
      let quotasModal = null
      if (!readOnly) {
        quotasModal = (
          <div className='row'>
            <div className='col s12'>
              <div>
                <QuotasModal showLink={questionnaire && survey.quotas.vars.length > 0} modalId='setupQuotas' linkText='EDIT QUOTAS' header='Quotas' confirmationText='DONE' showCancel onConfirm={vars => this.setQuotaVars(vars)} questionnaire={questionnaire} survey={survey} />
              </div>
            </div>
          </div>
        )
      }

      quotasForCompletes = (
        <div>
          <div className='row quotas'>
            <div className='col s12'>
              <input type='checkbox' className='filled-in' id='set-quotas' checked={survey.quotas.vars.length > 0} onChange={() => this.toggleQuotas()} disabled={readOnly} />
              <label htmlFor='set-quotas'>Quotas for completes</label>
              <p className='grey-text'>Quotas allow you to define minimum number of completed results for specific categories such as age or gender.</p>
            </div>
          </div>
          {quotasModal}
        </div>
      )
    }

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
          <div className='input-field col s8 l4'>
            <InputWithLabel id='completed-results' value={survey.cutoff || ''} label='Completed results' >
              <input
                type='text'
                onChange={e => this.cutoffChange(e)}
                disabled={readOnly}
              />
            </InputWithLabel>
          </div>
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
      </div>
    )
  }
}

export default connect()(SurveyWizardCutoffStep)
