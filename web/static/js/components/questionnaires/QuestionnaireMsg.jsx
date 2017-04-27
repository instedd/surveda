// @flow
import React, { Component } from 'react'
import { connect } from 'react-redux'
import { Card } from '../ui'
import * as actions from '../../actions/questionnaire'
import classNames from 'classnames'
import SmsPrompt from './SmsPrompt'
import IvrPrompt from './IvrPrompt'
import MobileWebPrompt from './MobileWebPrompt'
import { createAudio } from '../../api.js'
import { decamelize } from 'humps'
import { getPromptSms, getPromptIvr, getPromptIvrText, getPromptMobileWeb } from '../../step'
import * as api from '../../api'
import propsAreEqual from '../../propsAreEqual'
import { hasErrorsInPrefix } from '../../questionnaireErrors'

type Props = {
  dispatch: Function,
  questionnaire: ?Questionnaire,
  messageKey: string,
  title: string,
  icon: string,
  readOnly: boolean,
  errorsByPath: ErrorsByPath,
  hasErrors: boolean
};

type QuizState = {
  smsOriginalValue: string,
  ivrOriginalValue: string,
  mobilewebOriginalValue: string,
  stepPromptSms: string,
  stepPromptIvr: AudioPrompt,
  stepPromptIvrText: string,
  stepPromptMobileWeb: string,
  activeLanguage: string,
  cardId: string,
  questionnaireMsg: LanguagePrompt,
  audioErrors: string
};

type State = {
  editing: boolean,
  quizState: ?QuizState
};

class QuestionnaireMsg extends Component {
  props: Props
  state: State
  autocompleteItems: AutocompleteItem[]

  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props)
  }

  handleClick(e) {
    e.preventDefault()
    this.setState({editing: !this.state.editing})
  }

  promptSmsChange(text) {
    this.setState({
      quizState: {
        ...this.state.quizState,
        stepPromptSms: text
      }
    })
  }

  promptSmsSubmit(text) {
    const { dispatch, messageKey } = this.props
    dispatch(actions.setSmsQuestionnaireMsg(messageKey, text))
  }

  promptIvrChange(e) {
    e.preventDefault()
    this.setState({
      quizState: {
        ...this.state.quizState,
        stepPromptIvrText: e.target.value}
    })
  }

  promptIvrSubmit(e) {
    const { dispatch, messageKey } = this.props

    if (this.state.quizState) {
      dispatch(actions.setIvrQuestionnaireMsg(messageKey, {
        ...this.state.quizState.stepPromptIvr,
        text: e.target.value
      }))
    }
  }

  promptMobileWebChange(text) {
    this.setState({
      quizState: {
        ...this.state.quizState,
        stepPromptMobileWeb: text
      }
    })
  }

  promptMobileWebSubmit(text) {
    const { dispatch, messageKey } = this.props
    dispatch(actions.setMobileWebQuestionnaireMsg(messageKey, text))
  }

  changeIvrMode(e, mode) {
    e.preventDefault()
    const { dispatch, messageKey } = this.props

    if (this.state.quizState) {
      dispatch(actions.setIvrQuestionnaireMsg(messageKey, {
        ...this.state.quizState.stepPromptIvr,
        audioSource: mode
      }))
    }
  }

  componentWillReceiveProps(newProps) {
    if (propsAreEqual(this.props, newProps)) return

    this.setState(this.stateFromProps(newProps, this.state.editing))
  }

  stateFromProps(props: Props, editing = false): State {
    const { questionnaire, messageKey } = props

    if (!questionnaire) {
      return {
        editing: editing,
        quizState: null
      }
    }

    const activeLanguage = questionnaire.activeLanguage
    const questionnaireMsg = questionnaire.settings[messageKey] || {}

    const promptIvr = getPromptIvr(questionnaireMsg, activeLanguage)

    return {
      editing: editing,
      quizState: {
        smsOriginalValue: getPromptSms(questionnaireMsg, activeLanguage),
        ivrOriginalValue: getPromptIvrText(questionnaireMsg, activeLanguage),
        mobilewebOriginalValue: getPromptMobileWeb(questionnaireMsg, activeLanguage),
        stepPromptSms: getPromptSms(questionnaireMsg, activeLanguage),
        stepPromptIvr: promptIvr,
        stepPromptMobileWeb: getPromptMobileWeb(questionnaireMsg, activeLanguage),
        stepPromptIvrText: getPromptIvrText(questionnaireMsg, activeLanguage),
        questionnaireMsg: questionnaireMsg,
        cardId: `${decamelize(messageKey, '-')}-${activeLanguage}-card`,
        activeLanguage: activeLanguage,
        audioErrors: ''
      }
    }
  }

  handleFileUpload = (files) => {
    if (this.state.quizState) {
      const quizState = this.state.quizState
      createAudio(files)
        .then(response => {
          const { dispatch, messageKey } = this.props
          const ivr = quizState.stepPromptIvr
          dispatch(actions.setIvrQuestionnaireMsg(messageKey, {
            ...ivr,
            audioId: response.result
          }))
          $(`#${quizState.cardId} audio`)[0].load()
        })
        .catch((e) => {
          e.json()
            .then((response) => {
              let errors = (response.errors.data || ['Only mp3 and wav files are allowed.']).join(' ')
              this.setState({
                quizState: {
                  ...this.state.quizState,
                  audioErrors: errors
                }
              })
              $('#unprocessableEntity').modal('open')
            })
        })
    }
  }

  autocompleteGetData(value, callback, mode) {
    const { questionnaire, messageKey } = this.props
    if (!questionnaire) return

    const defaultLanguage = questionnaire.defaultLanguage
    const activeLanguage = questionnaire.activeLanguage
    const scope = messageKey == 'quotaCompletedMsg' ? 'quota_completed' : 'error'

    if (activeLanguage == defaultLanguage) {
      api.autocompletePrimaryLanguage(questionnaire.projectId, mode, scope, defaultLanguage, value)
      .then(response => {
        const items = response.map(r => ({id: r.text, text: r.text, translations: r.translations}))
        this.autocompleteItems = items
        callback(value, items)
      })
    } else {
      const questionnaireMsg = questionnaire[messageKey] || {}

      let promptValue
      if (mode == 'sms') {
        promptValue = getPromptSms(questionnaireMsg, defaultLanguage)
      } else {
        promptValue = getPromptIvrText(questionnaireMsg, defaultLanguage)
      }
      if (promptValue.length == 0) return

      api.autocompleteOtherLanguage(questionnaire.projectId, mode, scope, defaultLanguage, activeLanguage, promptValue, value)
      .then(response => {
        const items = response.map(r => ({id: r, text: r}))
        this.autocompleteItems = items
        callback(value, items)
      })
    }
  }

  autocompleteOnSelect(item, mode) {
    const { questionnaire, messageKey, dispatch } = this.props
    if (!questionnaire) return

    const defaultLanguage = questionnaire.defaultLanguage
    const activeLanguage = questionnaire.activeLanguage

    if (activeLanguage == defaultLanguage) {
      let value = this.autocompleteItems.find(i => i.id == item.id)
      if (mode == 'sms') {
        dispatch(actions.autocompleteSmsQuestionnaireMsg(messageKey, value))
      } else {
        dispatch(actions.autocompleteIvrQuestionnaireMsg(messageKey, value))
      }
    } else {
      if (mode == 'sms') {
        dispatch(actions.setSmsQuestionnaireMsg(messageKey, item.text))
      } else {
        let ivr = getPromptIvr(questionnaire[messageKey], activeLanguage)
        dispatch(actions.setIvrQuestionnaireMsg(messageKey, {
          ...ivr,
          text: item.text
        }))
      }
    }
  }

  collapsed() {
    const { title, icon, hasErrors } = this.props

    const iconClass = classNames({
      'material-icons left': true,
      'text-error': hasErrors
    })

    return (
      <ul className='collapsible dark'>
        <li>
          <Card>
            <div className='card-content closed-step'>
              <a className='truncate' href='#!' onClick={(e) => this.handleClick(e)}>
                <i className={iconClass}>{icon}</i>
                <span className={classNames({'text-error': hasErrors})}>{title} messages</span>
                <i className={classNames({'material-icons right grey-text': true, 'text-error': hasErrors})}>expand_more</i>
              </a>
            </div>
          </Card>
        </li>
      </ul>
    )
  }

  expanded(questionnaire: Questionnaire) {
    const { errorsByPath, messageKey, title, icon, readOnly } = this.props

    const sms = questionnaire.modes.indexOf('sms') != -1
    const ivr = questionnaire.modes.indexOf('ivr') != -1
    const mobileweb = questionnaire.modes.indexOf('mobileweb') != -1

    let smsInput = null

    if (this.state.quizState) {
      const quizState = this.state.quizState

      if (sms) {
        let smsInputErrors = errorsByPath[`${messageKey}.prompt['${questionnaire.activeLanguage}'].sms`]
        smsInput = <SmsPrompt id={`${decamelize(messageKey)}_sms`}
          inputErrors={smsInputErrors}
          value={quizState.stepPromptSms}
          originalValue={quizState.smsOriginalValue}
          readOnly={readOnly}
          onChange={text => this.promptSmsChange(text)}
          onBlur={text => this.promptSmsSubmit(text)}
          autocomplete
          autocompleteGetData={(value, callback) => this.autocompleteGetData(value, callback, 'sms')}
          autocompleteOnSelect={(item) => this.autocompleteOnSelect(item, 'sms')}
          />
      }

      let ivrInput = null

      if (ivr) {
        let ivrInputErrors = errorsByPath[`${messageKey}.prompt['${questionnaire.activeLanguage}'].ivr.text`]
        let ivrAudioIdErrors = errorsByPath[`${messageKey}.prompt['${questionnaire.activeLanguage}'].ivr.audioId`]
        ivrInput = <IvrPrompt id={`${decamelize(messageKey, '-')}-voice`}
          key={quizState.cardId}
          inputErrors={ivrInputErrors}
          audioIdErrors={ivrAudioIdErrors}
          value={quizState.stepPromptIvrText}
          originalValue={quizState.ivrOriginalValue}
          onChange={e => this.promptIvrChange(e)}
          readOnly={readOnly}
          onBlur={e => this.promptIvrSubmit(e)}
          changeIvrMode={(e, mode) => this.changeIvrMode(e, mode)}
          ivrPrompt={quizState.stepPromptIvr}
          customHandlerFileUpload={this.handleFileUpload}
          autocomplete
          autocompleteGetData={(value, callback) => this.autocompleteGetData(value, callback, 'ivr')}
          autocompleteOnSelect={(item) => this.autocompleteOnSelect(item, 'ivr')}
          />
      }

      let mobilewebInput = null

      if (mobileweb) {
        let mobilewebInputErrors = errorsByPath[`${messageKey}.prompt['${questionnaire.activeLanguage}'].mobileweb`]
        mobilewebInput = <MobileWebPrompt id={`${decamelize(messageKey, '-')}-mobile-web`}
          value={quizState.stepPromptMobileWeb}
          inputErrors={mobilewebInputErrors}
          originalValue={quizState.mobilewebOriginalValue}
          onChange={e => this.promptMobileWebChange(e)}
          readOnly={readOnly}
          onBlur={e => this.promptMobileWebSubmit(e)}
          />
      }

      return (
        <Card className='z-depth-0'>
          <ul className='collection collection-card dark' id={quizState.cardId} >
            <li className='collection-item header'>
              <div className='row'>
                <div className='col s12'>
                  <i className='material-icons left'>{icon}</i>
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
                {mobilewebInput}
              </div>
            </li>
          </ul>
        </Card>
      )
    } else {
      <div>Loading...</div>
    }
  }

  render() {
    const { questionnaire } = this.props
    if (!questionnaire) {
      return <div>Loading...</div>
    }

    if (this.state.editing) {
      return this.expanded(questionnaire)
    } else {
      return this.collapsed()
    }
  }
}

const mapStateToProps = (state, ownProps: Props) => {
  const quiz = (state.questionnaire: DataStore<Questionnaire>)
  return {
    questionnaire: quiz.data,
    errorsByPath: quiz.errorsByPath,
    hasErrors: hasErrorsInPrefix(quiz.errors, ownProps.messageKey)
  }
}

export default connect(mapStateToProps)(QuestionnaireMsg)
