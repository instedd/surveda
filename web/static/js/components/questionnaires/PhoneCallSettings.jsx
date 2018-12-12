import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Card } from '../ui'
import IvrPrompt from './IvrPrompt'
import { createAudio } from '../../api.js'
import classNames from 'classnames'
import propsAreEqual from '../../propsAreEqual'
import { getPromptIvr, getPromptIvrText } from '../../step'
import * as actions from '../../actions/questionnaire'
import * as api from '../../api'
import withQuestionnaire from './withQuestionnaire'
import { translate } from 'react-i18next'

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
      $('html, body').animate({scrollTop: elem.offset().top}, 500)
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

  messageBlur(text, key) {
    this.props.dispatch(actions.setIvrQuestionnaireMsg(key, {
      ...this.state[key],
      text
    }))
  }

  modeChange(e, mode, key) {
    e.preventDefault()
    this.props.dispatch(actions.setIvrQuestionnaireMsg(key, {
      ...this.state[key],
      audioSource: mode
    }))
  }

  handleFileUploadOrRecord = (files, key, load = true) => {
    createAudio(files)
      .then(response => {
        const { dispatch } = this.props
        const ivr = this.state[key]
        dispatch(actions.setIvrQuestionnaireMsg(key, {
          ...ivr,
          audioId: response.result
        }))
        if (load) {
          $(`.${key}Audio audio`)[0].load()
        }
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
                  <span className={classNames({'text-error': hasErrors})}>{this.props.t('Phone call settings')}</span>
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
                    <span>{this.props.t('Phone call settings')}</span>
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
      label={this.props.t('Error message')}
      inputErrors={ivrInputErrors}
      audioIdErrors={ivrAudioIdErrors}
      value={this.state.errorMessage.text}
      originalValue={this.state.errorMessage.text}
      readOnly={this.props.readOnly}
      onBlur={e => this.messageBlur(e, 'errorMessage')}
      changeIvrMode={(e, mode) => this.modeChange(e, mode, 'errorMessage')}
      ivrPrompt={this.state.errorMessage}
      customHandlerFileUpload={files => this.handleFileUploadOrRecord(files, 'errorMessage')}
      customHandlerRecord={files => this.handleFileUploadOrRecord(files, 'errorMessage', false)}
      autocomplete
      autocompleteGetData={(value, callback) => this.autocompleteGetData(value, callback, 'errorMessage')}
      autocompleteOnSelect={(item) => this.autocompleteOnSelect(item, 'errorMessage')}
      />
  }

  thankYouMessageComponent() {
    let ivrInputErrors = this.textErrors('thankYouMessage')
    let ivrAudioIdErrors = this.audioErrors('thankYouMessage')
    return <IvrPrompt
      label={this.props.t('Thank you message')}
      inputErrors={ivrInputErrors}
      audioIdErrors={ivrAudioIdErrors}
      value={this.state.thankYouMessage.text}
      originalValue={this.state.thankYouMessage.text}
      readOnly={this.props.readOnly}
      onBlur={e => this.messageBlur(e, 'thankYouMessage')}
      changeIvrMode={(e, mode) => this.modeChange(e, mode, 'thankYouMessage')}
      ivrPrompt={this.state.thankYouMessage}
      customHandlerFileUpload={files => this.handleFileUploadOrRecord(files, 'thankYouMessage')}
      customHandlerRecord={files => this.handleFileUploadOrRecord(files, 'thankYouMessage', false)}
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
    if (this.state.editing) {
      return this.expanded()
    } else {
      return this.collapsed()
    }
  }
}

PhoneCallSettings.propTypes = {
  dispatch: PropTypes.any,
  t: PropTypes.func,
  questionnaire: PropTypes.object,
  errorsByPath: PropTypes.object,
  errorMessage: PropTypes.object,
  thankYouMessage: PropTypes.object,
  readOnly: PropTypes.bool
}

const mapStateToProps = (state, ownProps) => ({
  errorsByPath: state.questionnaire.errorsByPath,
  errorMessage: getPromptIvr(ownProps.questionnaire.settings.errorMessage, ownProps.questionnaire.activeLanguage),
  thankYouMessage: getPromptIvr(ownProps.questionnaire.settings.thankYouMessage, ownProps.questionnaire.activeLanguage)
})

export default translate()(withQuestionnaire(connect(mapStateToProps)(PhoneCallSettings)))
