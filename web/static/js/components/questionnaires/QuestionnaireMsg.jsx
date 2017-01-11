// @flow
import React, { Component } from 'react'
import { connect } from 'react-redux'
import { Card } from '../ui'
import * as actions from '../../actions/questionnaire'
import classNames from 'classnames'
import SmsPrompt from './SmsPrompt'
import IvrPrompt from './IvrPrompt'
import { createAudio } from '../../api.js'
import { decamelize } from 'humps'
import { getPromptSms, getPromptIvr, getPromptIvrText } from '../../step'
import { msgPromptTextPath, msgHasErrors } from '../../questionnaireErrors'
import * as api from '../../api'

type Props = {
  dispatch: Function,
  questionnaire: Questionnaire,
  messageKey: string,
  title: string,
  icon: string,
  readOnly: boolean,
  activeLanguage: string,
  questionnaireMsg: string,
  errors: Errors,
  hasErrors: boolean,
  editing: boolean
};

type QuizState = {
  stepPromptSms: string,
  stepPromptIvr: LanguagePrompt,
  stepPromptIvrText: string,
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

  promptSmsChange(e) {
    e.preventDefault()
    this.setState({
      quizState: {
        ...this.state.quizState,
        stepPromptSms: e.target.value
      }
    })
  }

  promptSmsSubmit(e) {
    const { dispatch, messageKey } = this.props
    dispatch(actions.setSmsQuestionnaireMsg(messageKey, e.target.value))
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
    this.setState(this.stateFromProps({...newProps, editing: this.state.editing}))
  }

  stateFromProps(props: Props): State {
    const { questionnaire, messageKey, editing } = props

    if (!questionnaire) {
      return {
        editing: editing,
        quizState: null
      }
    }

    const activeLanguage = questionnaire.activeLanguage
    const questionnaireMsg = questionnaire[messageKey] || {}

    const promptIvr = getPromptIvr(questionnaireMsg, activeLanguage)

    return {
      editing: editing,
      quizState: {
        stepPromptSms: getPromptSms(questionnaireMsg, activeLanguage),
        stepPromptIvr: promptIvr,
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

    const defaultLanguage = questionnaire.defaultLanguage
    const activeLanguage = questionnaire.activeLanguage

    if (activeLanguage == defaultLanguage) {
      api.autocompletePrimaryLanguage(questionnaire.projectId, mode, defaultLanguage, value)
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

      api.autocompleteOtherLanguage(questionnaire.projectId, mode, defaultLanguage, activeLanguage, promptValue, value)
      .then(response => {
        const items = response.map(r => ({id: r, text: r}))
        this.autocompleteItems = items
        callback(value, items)
      })
    }
  }

  autocompleteOnSelect(item, mode) {
    const { questionnaire, messageKey, dispatch } = this.props

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

  expanded() {
    const { questionnaire, errors, messageKey, title, icon, readOnly } = this.props

    const sms = questionnaire.modes.indexOf('sms') != -1
    const ivr = questionnaire.modes.indexOf('ivr') != -1

    let smsInput = null

    if (this.state.quizState) {
      const quizState = this.state.quizState

      if (sms) {
        let smsInputErrors = errors[msgPromptTextPath(messageKey, 'sms', questionnaire.activeLanguage)]
        smsInput = <SmsPrompt id={`${decamelize(messageKey)}_sms`}
          inputErrors={smsInputErrors}
          value={quizState.stepPromptSms}
          readOnly={readOnly}
          onChange={e => this.promptSmsChange(e)}
          onBlur={e => this.promptSmsSubmit(e)}
          autocomplete
          autocompleteGetData={(value, callback) => this.autocompleteGetData(value, callback, 'sms')}
          autocompleteOnSelect={(item) => this.autocompleteOnSelect(item, 'sms')}
          />
      }

      let ivrInput = null

      if (ivr) {
        let ivrInputErrors = errors[msgPromptTextPath(messageKey, 'ivr', questionnaire.activeLanguage)]
        ivrInput = <IvrPrompt id={`${decamelize(messageKey, '-')}-voice`}
          key={quizState.cardId}
          inputErrors={ivrInputErrors}
          value={quizState.stepPromptIvrText}
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

const mapStateToProps = (state, ownProps: Props) => {
  const quiz = (state.questionnaire: DataStore<Questionnaire>)
  return {
    questionnaire: quiz.data,
    readOnly: state.project && state.project.data ? state.project.data.readOnly : true,
    errors: quiz.data ? quiz.errorsByLang[quiz.data.activeLanguage] : {},
    hasErrors: quiz.data ? msgHasErrors(quiz, ownProps.messageKey) : false
  }
}

export default connect(mapStateToProps)(QuestionnaireMsg)
