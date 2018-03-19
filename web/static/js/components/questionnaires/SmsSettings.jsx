import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Card } from '../ui'
import SmsPrompt from './SmsPrompt'
import classNames from 'classnames'
import propsAreEqual from '../../propsAreEqual'
import { getPromptSms } from '../../step'
import * as actions from '../../actions/questionnaire'
import * as api from '../../api'
import withQuestionnaire from './withQuestionnaire'
import { translate } from 'react-i18next'

class SmsSettings extends Component {
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

  messageBlur(text, key) {
    this.props.dispatch(actions.setSmsQuestionnaireMsg(key, text))
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
                  <span className={classNames({'text-error': hasErrors})}>{this.props.t('SMS settings')}</span>
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
                    <span>{this.props.t('SMS settings')}</span>
                  </a>
                  <a className='collapse right' href='#!' onClick={(e) => this.handleClick(e)}>
                    <i className='material-icons'>expand_less</i>
                  </a>
                </div>
              </div>
            </li>
            <li className='collection-item'>
              {this.errorMessageComponent()}
            </li>
            <li className='collection-item'>
              {this.thankYouMessageComponent()}
            </li>
          </ul>
        </Card>
      </div>
    )
  }

  errorMessageComponent() {
    return <SmsPrompt id='sms_settings_error'
      label={this.props.t('Error message')}
      inputErrors={this.messageErrors('errorMessage')}
      value={this.state.errorMessage}
      originalValue={this.state.errorMessage}
      readOnly={this.props.readOnly}
      onBlur={text => this.messageBlur(text, 'errorMessage')}
      autocomplete
      autocompleteGetData={(value, callback) => this.autocompleteGetData(value, callback, 'errorMessage')}
      autocompleteOnSelect={(item) => this.autocompleteOnSelect(item, 'errorMessage')}
      />
  }

  thankYouMessageComponent() {
    return <SmsPrompt id='sms_settings_thank_you'
      label={this.props.t('Thank you message')}
      inputErrors={this.messageErrors('thankYouMessage')}
      value={this.state.thankYouMessage}
      originalValue={this.state.thankYouMessage}
      readOnly={this.props.readOnly}
      onBlur={text => this.messageBlur(text, 'thankYouMessage')}
      autocomplete
      autocompleteGetData={(value, callback) => this.autocompleteGetData(value, callback, 'thankYouMessage')}
      autocompleteOnSelect={(item) => this.autocompleteOnSelect(item, 'thankYouMessage')}
      />
  }

  messageErrors(key) {
    const { questionnaire, errorsByPath } = this.props
    return errorsByPath[`${key}.prompt['${questionnaire.activeLanguage}'].sms`]
  }

  hasErrors() {
    return !!this.messageErrors('errorMessage')
  }

  autocompleteGetData(value, callback, key) {
    const { questionnaire } = this.props

    const defaultLanguage = questionnaire.defaultLanguage
    const activeLanguage = questionnaire.activeLanguage
    const scope = key == 'errorMessage' ? 'error' : 'thank_you'

    if (activeLanguage == defaultLanguage) {
      api.autocompletePrimaryLanguage(questionnaire.projectId, 'sms', scope, defaultLanguage, value)
      .then(response => {
        const items = response.map(r => ({id: r.text, text: r.text, translations: r.translations}))
        this.autocompleteItems = items
        callback(value, items)
      })
    } else {
      const questionnaireMsg = questionnaire.settings[key] || {}

      let promptValue = getPromptSms(questionnaireMsg, defaultLanguage)
      if (promptValue.length == 0) return

      api.autocompleteOtherLanguage(questionnaire.projectId, 'sms', scope, defaultLanguage, activeLanguage, promptValue, value)
      .then(response => {
        const items = response.map(r => ({id: r, text: r}))
        this.autocompleteItems = items
        callback(value, items)
      })
    }
  }

  autocompleteOnSelect(item, key) {
    const { questionnaire, dispatch } = this.props

    const defaultLanguage = questionnaire.defaultLanguage
    const activeLanguage = questionnaire.activeLanguage

    if (activeLanguage == defaultLanguage) {
      let value = this.autocompleteItems.find(i => i.id == item.id)
      dispatch(actions.autocompleteSmsQuestionnaireMsg(key, value))
    } else {
      dispatch(actions.setSmsQuestionnaireMsg(key, item.text))
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

SmsSettings.propTypes = {
  dispatch: PropTypes.any,
  questionnaire: PropTypes.object,
  errorsByPath: PropTypes.object,
  errorMessage: PropTypes.string,
  t: PropTypes.func,
  thankYouMessage: PropTypes.string,
  readOnly: PropTypes.bool
}

const mapStateToProps = (state, ownProps) => ({
  errorsByPath: state.questionnaire.errorsByPath,
  errorMessage: getPromptSms(ownProps.questionnaire.settings.errorMessage, ownProps.questionnaire.activeLanguage),
  thankYouMessage: getPromptSms(ownProps.questionnaire.settings.thankYouMessage, ownProps.questionnaire.activeLanguage)
})

export default translate()(withQuestionnaire(connect(mapStateToProps)(SmsSettings)))
