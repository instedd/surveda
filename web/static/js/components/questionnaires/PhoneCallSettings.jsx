import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Card } from '../ui'
import IvrPrompt from './IvrPrompt'
import { createAudio } from '../../api.js'
import classNames from 'classnames'
import propsAreEqual from '../../propsAreEqual'
import { getPromptIvr, getPromptIvrText, newIvrPrompt } from '../../step'
import * as actions from '../../actions/questionnaire'
import * as api from '../../api'

class PhoneCallSettings extends Component {
  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props, false)
  }

  handleClick(e) {
    e.preventDefault()
    this.setState({editing: !this.state.editing}, this.scrollIfNeeded)
  }

  scrollIfNeeded() {
    if (this.state.editing) {
      const elem = $(this.refs.self)
      $('body').animate({scrollTop: elem.offset().top}, 500)
    }
  }

  componentWillReceiveProps(newProps) {
    if (propsAreEqual(this.props, newProps)) return

    this.setState(this.stateFromProps(newProps))
  }

  stateFromProps(props) {
    return {
      errorMessage: props.errorMessage,
      thankYouMessage: props.thankYouMessage
    }
  }

  textChange(e, key) {
    e.preventDefault()
    this.setState({
      [key]: {
        ...this.state[key],
        text: e.target.value
      }
    })
  }

  messageBlur(e, key) {
    this.props.dispatch(actions.setIvrQuestionnaireMsg(key, {
      ...this.state[key],
      text: e.target.value
    }))
  }

  modeChange(e, mode, key) {
    e.preventDefault()
    this.props.dispatch(actions.setIvrQuestionnaireMsg(key, {
      ...this.state[key],
      audioSource: mode
    }))
  }

  handleFileUpload = (files, key) => {
    createAudio(files)
      .then(response => {
        const { dispatch } = this.props
        const ivr = this.state[key]
        dispatch(actions.setIvrQuestionnaireMsg(key, {
          ...ivr,
          audioId: response.result
        }))
        $(`.${key}Audio audio`)[0].load()
      })
      .catch((e) => {
        e.json()
          .then((response) => {
            $('#unprocessableEntity').modal('open')
          })
      })
  }

  collapsed() {
    let hasErrors = this.hasErrors()

    const iconClass = classNames({
      'material-icons left': true,
      'text-error': hasErrors
    })

    return (
      <div className='row'>
        <ul className='collapsible dark'>
          <li>
            <Card>
              <div className='card-content closed-step'>
                <a className='truncate' href='#!' onClick={(e) => this.handleClick(e)}>
                  <i className={iconClass}>build</i>
                  <span className={classNames({'text-error': hasErrors})}>Phone call settings</span>
                  <i className={classNames({'material-icons right grey-text': true, 'text-error': hasErrors})}>expand_more</i>
                </a>
              </div>
            </Card>
          </li>
        </ul>
      </div>
    )
  }

  expanded() {
    return (
      <div className='row' ref='self'>
        <Card className='z-depth-0'>
          <ul className='collection collection-card dark'>
            <li className='collection-item header'>
              <div className='row'>
                <div className='col s12'>
                  <i className='material-icons left'>build</i>
                  <a className='page-title truncate'>
                    <span>Phone call settings</span>
                  </a>
                  <a className='collapse right' href='#!' onClick={(e) => this.handleClick(e)}>
                    <i className='material-icons'>expand_less</i>
                  </a>
                </div>
              </div>
            </li>
            <li className='collection-item errorMessageAudio'>
              {this.errorMessageComponent()}
            </li>
            <li className='collection-item thankYouMessageAudio'>
              {this.thankYouMessageComponent()}
            </li>
          </ul>
        </Card>
      </div>
    )
  }

  errorMessageComponent() {
    let ivrInputErrors = this.textErrors('errorMessage')
    let ivrAudioIdErrors = this.audioErrors('errorMessage')
    return <IvrPrompt
      label='Error message'
      inputErrors={ivrInputErrors}
      audioIdErrors={ivrAudioIdErrors}
      value={this.state.errorMessage.text}
      originalValue={this.state.errorMessage.text}
      readOnly={this.props.readOnly}
      onBlur={e => this.messageBlur(e, 'errorMessage')}
      changeIvrMode={(e, mode) => this.modeChange(e, mode, 'errorMessage')}
      ivrPrompt={this.state.errorMessage}
      customHandlerFileUpload={files => this.handleFileUpload(files, 'errorMessage')}
      autocomplete
      autocompleteGetData={(value, callback) => this.autocompleteGetData(value, callback, 'errorMessage')}
      autocompleteOnSelect={(item) => this.autocompleteOnSelect(item, 'errorMessage')}
      />
  }

  thankYouMessageComponent() {
    let ivrInputErrors = this.textErrors('thankYouMessage')
    let ivrAudioIdErrors = this.audioErrors('thankYouMessage')
    return <IvrPrompt
      label='Thank you message'
      inputErrors={ivrInputErrors}
      audioIdErrors={ivrAudioIdErrors}
      value={this.state.thankYouMessage.text}
      originalValue={this.state.thankYouMessage.text}
      readOnly={this.props.readOnly}
      onBlur={e => this.messageBlur(e, 'thankYouMessage')}
      changeIvrMode={(e, mode) => this.modeChange(e, mode, 'thankYouMessage')}
      ivrPrompt={this.state.thankYouMessage}
      customHandlerFileUpload={files => this.handleFileUpload(files, 'thankYouMessage')}
      autocomplete
      autocompleteGetData={(value, callback) => this.autocompleteGetData(value, callback, 'thankYouMessage')}
      autocompleteOnSelect={(item) => this.autocompleteOnSelect(item, 'thankYouMessage')}
      />
  }

  textErrors(key) {
    const { questionnaire, errorsByPath } = this.props
    return errorsByPath[`${key}.prompt['${questionnaire.activeLanguage}'].ivr.text`]
  }

  audioErrors(key) {
    const { questionnaire, errorsByPath } = this.props
    return errorsByPath[`${key}.prompt['${questionnaire.activeLanguage}'].ivr.audioId`]
  }

  hasErrors() {
    return !!this.textErrors('errorMessage') ||
      !!this.audioErrors('errorMessage')
  }

  autocompleteGetData(value, callback, key) {
    const { questionnaire } = this.props
    if (!questionnaire) return

    const defaultLanguage = questionnaire.defaultLanguage
    const activeLanguage = questionnaire.activeLanguage
    const scope = key == 'errorMessage' ? 'error' : 'thank_you'

    if (activeLanguage == defaultLanguage) {
      api.autocompletePrimaryLanguage(questionnaire.projectId, 'ivr', scope, defaultLanguage, value)
      .then(response => {
        const items = response.map(r => ({id: r.text, text: r.text, translations: r.translations}))
        this.autocompleteItems = items
        callback(value, items)
      })
    } else {
      const questionnaireMsg = questionnaire[key] || {}

      let promptValue = getPromptIvrText(questionnaireMsg, defaultLanguage)
      if (promptValue.length == 0) return

      api.autocompleteOtherLanguage(questionnaire.projectId, 'ivr', scope, defaultLanguage, activeLanguage, promptValue, value)
      .then(response => {
        const items = response.map(r => ({id: r, text: r}))
        this.autocompleteItems = items
        callback(value, items)
      })
    }
  }

  autocompleteOnSelect(item, key) {
    const { questionnaire, dispatch } = this.props
    if (!questionnaire) return

    const defaultLanguage = questionnaire.defaultLanguage
    const activeLanguage = questionnaire.activeLanguage

    if (activeLanguage == defaultLanguage) {
      let value = this.autocompleteItems.find(i => i.id == item.id)
      dispatch(actions.autocompleteIvrQuestionnaireMsg(key, value))
    } else {
      let ivr = getPromptIvr(questionnaire[key], activeLanguage)
      dispatch(actions.setIvrQuestionnaireMsg(key, {
        ...ivr,
        text: item.text
      }))
    }
  }

  render() {
    const { questionnaire } = this.props
    if (!questionnaire) {
      return <div>Loading...</div>
    }

    if (this.state.editing) {
      return this.expanded()
    } else {
      return this.collapsed()
    }
  }
}

PhoneCallSettings.propTypes = {
  dispatch: PropTypes.any,
  questionnaire: PropTypes.object,
  errorsByPath: PropTypes.object,
  errorMessage: PropTypes.object,
  thankYouMessage: PropTypes.object,
  readOnly: PropTypes.bool
}

const mapStateToProps = (state, ownProps) => {
  const quiz = state.questionnaire
  return {
    questionnaire: quiz.data,
    errorsByPath: quiz.errorsByPath,
    errorMessage: quiz.data ? getPromptIvr(quiz.data.settings.errorMessage, quiz.data.activeLanguage) : newIvrPrompt(),
    thankYouMessage: quiz.data ? getPromptIvr(quiz.data.settings.thankYouMessage, quiz.data.activeLanguage) : newIvrPrompt()
  }
}

export default connect(mapStateToProps)(PhoneCallSettings)
