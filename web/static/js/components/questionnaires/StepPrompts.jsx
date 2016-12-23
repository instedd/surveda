import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as questionnaireActions from '../../actions/questionnaire'
import SmsPrompt from './SmsPrompt'
import IvrPrompt from './IvrPrompt'

class StepPrompts extends Component {

  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props)
  }

  stepPromptSmsChange(e) {
    e.preventDefault()
    this.setState({stepPromptSms: e.target.value})
  }

  stepPromptSmsSubmit(e) {
    e.preventDefault()
    const { stepId } = this.props
    this.props.questionnaireActions.changeStepPromptSms(stepId, e.target.value)
  }

  stepPromptIvrChange(e) {
    e.preventDefault()
    this.setState({stepPromptIvrText: e.target.value})
  }

  stepPromptIvrSubmit(e) {
    e.preventDefault()
    const { stepId } = this.props
    this.props.questionnaireActions.changeStepPromptIvr(stepId, {text: e.target.value, audioSource: 'tts'})
  }

  changeIvrMode(e, mode) {
    const { stepId } = this.props
    this.props.questionnaireActions.changeStepPromptIvr(stepId, {text: this.state.stepPromptIvr, audioSource: mode})
  }

  componentWillReceiveProps(newProps) {
    this.setState(this.stateFromProps(newProps))
  }

  stateFromProps(props) {
    const { stepPrompt } = props

    return {
      stepPromptSms: (stepPrompt || {}).sms || '',
      stepPromptIvr: (stepPrompt || {}).ivr,
      stepPromptIvrText: ((stepPrompt || {}).ivr || {}).text || ''
    }
  }

  render() {
    const { sms, ivr, stepId } = this.props

    let smsInput = null
    if (sms) {
      // TODO: uncomment line below once error styles are fixed
      let smsInputErrors = null // errors[`${errorPath}.prompt.sms`]
      smsInput = <SmsPrompt id='step_editor_sms_prompt' value={this.state.stepPromptSms} inputErrors={smsInputErrors} onChange={e => this.stepPromptSmsChange(e)} onBlur={e => this.stepPromptSmsSubmit(e)} />
    }

    let ivrInput = null
    if (ivr) {
      // TODO: uncomment line below once error styles are fixed
      let ivrInputErrors = null // errors[`${errorPath}.prompt.ivr.text`]
      ivrInput = <IvrPrompt id='step_editor_ivr_prompt' value={this.state.stepPromptIvrText} inputErrors={ivrInputErrors} onChange={e => this.stepPromptIvrChange(e)} onBlur={e => this.stepPromptIvrSubmit(e)} changeIvrMode={(e, mode) => this.changeIvrMode(e, mode)} stepId={stepId} ivrPrompt={this.state.stepPromptIvr} />
    }

    return (
      <li className='collection-item' key='prompts'>
        <div className='row'>
          <div className='col s12'>
            <h5>Question Prompt</h5>
          </div>
        </div>
        {smsInput}
        {ivrInput}
      </li>
    )
  }
}

StepPrompts.propTypes = {
  questionnaireActions: PropTypes.any,
  stepPrompt: PropTypes.object.isRequired,
  stepId: PropTypes.string.isRequired,
  sms: PropTypes.bool.isRequired,
  ivr: PropTypes.bool.isRequired,
  inputErrors: PropTypes.bool
}

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(null, mapDispatchToProps)(StepPrompts)
