import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Card } from '../ui'
import * as actions from '../../actions/questionnaire'
import SmsPrompt from './SmsPrompt'
import IvrPrompt from './IvrPrompt'
import { createAudio } from '../../api.js'
import { decamelize } from 'humps'
import { getPromptSms, getPromptIvr, getPromptIvrText } from '../../step'

class QuestionnaireMsg extends Component {
  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    questionnaire: PropTypes.object,
    messageKey: PropTypes.string.isRequired,
    title: PropTypes.string.isRequired,
    activeLanguage: PropTypes.string,
    questionnaireMsg: PropTypes.string
  }

  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props)
  }

  handleClick(e) {
    e.preventDefault()
    this.setState({editing: !this.state.editing})
  }

  promptSmsChange(e) {
    e.preventDefault()
    this.setState({stepPromptSms: e.target.value})
  }

  promptSmsSubmit(e) {
    const { dispatch, messageKey } = this.props
    dispatch(actions.setSmsQuestionnaireMsg(messageKey, e.target.value))
  }

  promptIvrChange(e) {
    e.preventDefault()
    this.setState({stepPromptIvrText: e.target.value})
  }

  promptIvrSubmit(e) {
    const { dispatch, messageKey } = this.props

    dispatch(actions.setIvrQuestionnaireMsg(messageKey, {
      ...this.state.stepPromptIvr,
      text: e.target.value
    }))
  }

  changeIvrMode(e, mode) {
    e.preventDefault()
    const { dispatch, messageKey } = this.props

    dispatch(actions.setIvrQuestionnaireMsg(messageKey, {
      ...this.state.stepPromptIvr,
      audioSource: mode
    }))
  }

  componentWillReceiveProps(newProps) {
    this.setState(this.stateFromProps({...newProps, editing: this.state.editing}))
  }

  stateFromProps(props) {
    const { questionnaire, messageKey, editing } = props
    const activeLanguage = questionnaire.activeLanguage
    const questionnaireMsg = questionnaire[messageKey] || {}

    const promptIvr = getPromptIvr(questionnaireMsg, activeLanguage)

    return {
      stepPromptSms: getPromptSms(questionnaireMsg, activeLanguage),
      stepPromptIvr: promptIvr,
      stepPromptIvrText: getPromptIvrText(questionnaireMsg, activeLanguage),
      questionnaireMsg: questionnaireMsg,
      activeLanguage: activeLanguage,
      editing: editing
    }
  }

  handleFileUpload = (files) => {
    let self = this

    createAudio(files)
      .then(response => {
        const { dispatch, messageKey } = self.props
        const ivr = self.state.stepPromptIvr
        dispatch(actions.setIvrQuestionnaireMsg(messageKey, {
          ...ivr,
          audioId: response.result
        }))
        $(`#${decamelize(messageKey, '-')}-card audio`)[0].load()
      })
      .catch((e) => {
        e.json()
         .then((response) => {
           let errors = (response.errors.data || ['Only mp3 and wav files are allowed.']).join(' ')
           this.setState({audioErrors: errors})
           $('#unprocessableEntity').modal('open')
         })
      })
  }

  collapsed() {
    const { title } = this.props

    return (
      <ul className='collapsible dark'>
        <li>
          <Card>
            <div className='card-content closed-step'>
              <a className='truncate' href='#!' onClick={(e) => this.handleClick(e)}>
                <i className='material-icons left'>pie_chart</i>
                <span>{title} messages</span>
                <i className='material-icons right grey-text'>expand_more</i>
              </a>
            </div>
          </Card>
        </li>
      </ul>
    )
  }

  expanded() {
    const { questionnaire, messageKey, title } = this.props

    const sms = questionnaire.modes.indexOf('sms') != -1
    const ivr = questionnaire.modes.indexOf('ivr') != -1

    let smsInput = null

    if (sms) {
      smsInput = <SmsPrompt id={`${decamelize(messageKey)}_sms`} value={this.state.stepPromptSms} onChange={e => this.promptSmsChange(e)} onBlur={e => this.promptSmsSubmit(e)} />
    }

    let ivrInput = null

    if (ivr) {
      ivrInput = <IvrPrompt id={`${decamelize(messageKey, '-')}-voice`} value={this.state.stepPromptIvrText} onChange={e => this.promptIvrChange(e)} onBlur={e => this.promptIvrSubmit(e)} changeIvrMode={(e, mode) => this.changeIvrMode(e, mode)} ivrPrompt={this.state.stepPromptIvr} customHandlerFileUpload={this.handleFileUpload} />
    }

    return (
      <Card>
        <ul className='collection collection-card dark' id={`${decamelize(messageKey, '-')}-card`} >
          <li className='collection-item header'>
            <div className='row'>
              <div className='col s12'>
                <i className='material-icons left'>pie_chart</i>
                <a className='page-title truncate'>
                  <span>{title} messages</span>
                </a>
                <a className='collapse right' href='#!' onClick={(e) => this.handleClick(e)}>
                  <i className='material-icons'>expand_less</i>
                </a>
              </div>
            </div>
          </li>
          <li className='collection-item'>
            <div>
              {smsInput}
              {ivrInput}
            </div>
          </li>
        </ul>
      </Card>
    )
  }

  render() {
    if (!this.props.questionnaire) {
      return <div>Loading...</div>
    }

    if (this.state.editing) {
      return this.expanded()
    } else {
      return this.collapsed()
    }
  }
}

const mapStateToProps = (state) => ({
  questionnaire: state.questionnaire.data
})

export default connect(mapStateToProps)(QuestionnaireMsg)
