import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import * as actions from '../../actions/survey'
import * as uiActions from '../../actions/ui'
import QuotasModal from './QuotasModal'
import { InputWithLabel } from '../ui'
import find from 'lodash/find'
import join from 'lodash/join'
import { stepStoreValues } from '../../reducers/questionnaire'
import { translate } from 'react-i18next'

class SurveyWizardCutoffStep extends Component {
  static propTypes = {
    t: PropTypes.func,
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

  componentWillMount(){ 
    const {dispatch, survey} = this.props
    dispatch(uiActions.setInitialCutOffConfig(survey))
  }

  cutoffChange(e) {
    e.preventDefault()
    const { dispatch } = this.props
    var onlyNumbers = e.target.value.replace(/[^0-9]/g, '')
    let newCutoff;
    if (!parseInt(onlyNumbers)) {
      newCutoff = 0
    } else if (onlyNumbers == e.target.value && onlyNumbers < Math.pow(2, 31) - 1) {
      newCutoff = onlyNumbers
    }
    dispatch(actions.changeCutoff(newCutoff))     
    dispatch(uiActions.surveyCutOffConfigValid(this.props.cutOffConfig, newCutoff))
  }

  quotaChange(e) {
    e.preventDefault()
    const { dispatch, survey } = this.props
    var onlyNumbers = e.target.value.replace(/[^0-9]/g, '')

    if (onlyNumbers == e.target.value && onlyNumbers < Math.pow(2, 31) - 1) {
      const condition = find(survey.quotas.buckets, (bucket) =>
        this.bucketLabel(bucket) == e.target.id
      ).condition
      const toChange = {buckets: survey.quotas.buckets, condition, onlyNumbers}
      dispatch(actions.quotaChange(condition, onlyNumbers))
      dispatch(uiActions.surveyCutOffConfigValid(this.props.cutOffConfig, toChange))
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
    const { t } = this.props
    return (
      <div className='row'>
        <div className='col s12'>
          <h4>{t('Configure cutoff rules')}</h4>
          <p className='flow-text'>
            {t('Cutoff rules define when the survey will stop. You can use one or more of these options. If you don\'t select any, the survey will be sent to all respondents.')}
          </p>
        </div>
      </div>
    )
  }

  quotaErrorMessage(quotasSum) {
    const {t, cutOffConfig} = this.props
    let errorMessage = ''
    if(cutOffConfig === 'quota'){
      if(isNaN(quotasSum) && quotasSum !== undefined){
        errorMessage = t('All quota fields are required, please fill them to continue')
      } else {
        if(quotasSum == 0) {
          errorMessage = t('All quotas are empty. Increase at least one of them to continue')
        }
      }
      return(
        <div className='row'>
          <div className='col s12'>
            <p className='text-error'>
              {errorMessage}
            </p>
          </div>
        </div>
      )
    }
  }

  handleConfigChange(config){
    const {dispatch, questionnaire, survey} = this.props
    switch(config){
      default:
      case 'default': {
        dispatch(actions.changeCutoff(null))
        this.turnOffQuotas()
        break
      }
      case 'cutoff' : {
        dispatch(actions.changeCutoff(0))
        this.turnOffQuotas()
        break
      }
      case 'quota' : {
        this.turnOnQuotas();
        break
      }
    }
    dispatch(uiActions.surveySetCutOffConfig(config))
  }

  renderWithQuotas() {
    const { questionnaire, survey, readOnly, cutOffConfig, quotasSum, t } = this.props
    const hasQuotas = questionnaire && survey.quotas.vars.length > 0

    let quotasModal = null
    if (!readOnly) {
      quotasModal = (
        <div className='row'>
          <div className='col s12'>
            <QuotasModal showLink={hasQuotas} modalId='setupQuotas' linkText={t('EDIT QUOTAS')} header={t('Quotas')} confirmationText={t('Done')} showCancel onConfirm={vars => this.setQuotaVars(vars)} questionnaire={questionnaire} survey={survey} />
          </div>
        </div>
      )
    }
    let quotasForCompletes = (
      <div>
        <div className='row quotas'>
          <div className='col s12'>
            <input type='radio' className='filled-in with-gap' id='set-quotas' checked={cutOffConfig === 'quota'} onChange={() => this.handleConfigChange('quota')} disabled={readOnly} />
            <label htmlFor='set-quotas'>{t('Quotas for completes')}</label>
            <p className='grey-text'>{t('Quotas allow you to define minimum number of completed results for specific categories such as age or gender.')}</p>
            {this.quotaErrorMessage(quotasSum)}
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
    const partialsLabel = <label className='bottom-margin' htmlFor='toggle_count_partial_results'>{t('Count partials as completed')}</label>

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
            <input type='radio' className='with-gap' id='survey_default_cutoff' disabled={readOnly} checked={cutOffConfig === 'default'} onChange={()=> this.handleConfigChange('default')}/>
            <label htmlFor='survey_default_cutoff'>{t('No cutoff')}</label>
          </div>
        </div>
        <div className='row'>
          <div className='col s12'>
            <input type='radio' className='with-gap' id='survey_cutoff' checked={cutOffConfig === 'cutoff'} onChange={() => this.handleConfigChange('cutoff')} disabled={readOnly} />
            <label htmlFor='survey_cutoff'>{t('Number of completes')}</label>
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
    const { survey, readOnly, t } = this.props

    return (
      <div>
        {this.header()}
        <div className='row'>
          <div className='col s12'>
            {t('Number of completes')}
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
              <label htmlFor='toggle_count_partial_results'>{t('Count partials as completed')}</label>
            </div>
          </div>
        </div>
      </div>
    )
  }

  render() {
    const { questionnaire, survey } = this.props
    const hasQuotas = questionnaire && (Object.keys(stepStoreValues(questionnaire)).length || survey.quotas.vars.length > 0)
    if (hasQuotas) {
      return this.renderWithQuotas()
    } else {
      return this.renderWithoutQuotas()
    }
  }
}

const mapStateToProps = (state) =>{
  return({
    cutOffConfig : state.ui.data.surveyWizard.cutOffConfig,
    quotasSum: state.ui.data.surveyWizard.quotasSum
  })
}

export default translate()(connect(mapStateToProps)(SurveyWizardCutoffStep))
