import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Card, InputWithLabel } from '../ui'
import SmsPrompt from './SmsPrompt'
import MobileWebPrompt from './MobileWebPrompt'
import classNames from 'classnames'
import propsAreEqual from '../../propsAreEqual'
import { getPromptMobileWeb } from '../../step'
import * as actions from '../../actions/questionnaire'
import withQuestionnaire from './withQuestionnaire'
import { translate } from 'react-i18next'

class WebSettings extends Component {
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
      thankYouMessage: props.thankYouMessage,
      title: props.title,
      smsMessage: props.smsMessage,
      surveyIsOverMessage: props.surveyIsOverMessage,
      surveyAlreadyTakenMessage: props.surveyAlreadyTakenMessage,
      primaryColor: props.primaryColor,
      secondaryColor: props.secondaryColor
    }
  }

  messageChange(text, key) {
    this.setState({[key]: text})
  }

  messageBlur(text, key) {
    this.props.dispatch(actions.setMobileWebQuestionnaireMsg(key, text))
  }

  titleBlur(text) {
    this.props.dispatch(actions.setDisplayedTitle(text))
  }

  smsMessageBlur(text) {
    this.props.dispatch(actions.setMobileWebSmsMessage(text))
  }

  surveyIsOverMessageBlur(text) {
    this.props.dispatch(actions.setMobileWebSurveyIsOverMessage(text))
  }

  surveyAlreadyTakenMessageBlur(text) {
    this.props.dispatch(actions.setSurveyAlreadyTakenMessage(text))
  }

  colorSelectionBlur(text, mode) {
    const { dispatch } = this.props
    if (mode == 'primary') {
      dispatch(actions.setPrimaryColor(this.state.primaryColor))
    } else {
      dispatch(actions.setSecondaryColor(this.state.secondaryColor))
    }
  }

  collapsed() {
    let hasErrors = this.hasErrors()

    const { t } = this.props

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
                  <span className={classNames({'text-error': hasErrors})}>{t('Web settings')}</span>
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
    const { t } = this.props
    return (
      <div className='row' ref='self'>
        <Card className='z-depth-0'>
          <ul className='collection collection-card dark'>
            <li className='collection-item header'>
              <div className='row'>
                <div className='col s12'>
                  <i className='material-icons left'>build</i>
                  <a className='page-title truncate'>
                    <span>{t('Web settings')}</span>
                  </a>
                  <a className='collapse right' href='#!' onClick={(e) => this.handleClick(e)}>
                    <i className='material-icons'>expand_less</i>
                  </a>
                </div>
              </div>
            </li>
            <li className='collection-item'>
              {this.colorSelectionComponent()}
            </li>
            <li className='collection-item'>
              <h5>
                {t('Messages')}
              </h5>
              {this.errorMessageComponent()}
            </li>
            <li className='collection-item'>
              {this.thankYouMessageComponent()}
            </li>
            <li className='collection-item'>
              {this.titleComponent()}
            </li>
            <li className='collection-item'>
              {this.smsMessageComponent()}
            </li>
            <li className='collection-item'>
              {this.surveyIsOverMessageComponent()}
            </li>
            <li className='collection-item'>
              {this.surveyAlreadyTakenMessageComponent()}
            </li>
          </ul>
        </Card>
      </div>
    )
  }

  errorMessageComponent() {
    return <MobileWebPrompt id='web_settings_error'
      label={this.props.t('Error message')}
      inputErrors={this.messageErrors('errorMessage')}
      value={this.state.errorMessage}
      originalValue={this.state.errorMessage}
      onBlur={text => this.messageBlur(text, 'errorMessage')}
      readOnly={this.props.readOnly}
      />
  }

  thankYouMessageComponent() {
    return <MobileWebPrompt id='web_settings_thank_you'
      label={this.props.t('Thank you message')}
      inputErrors={this.messageErrors('thankYouMessage')}
      value={this.state.thankYouMessage}
      originalValue={this.state.thankYouMessage}
      onBlur={text => this.messageBlur(text, 'thankYouMessage')}
      readOnly={this.props.readOnly}
      />
  }

  titleComponent() {
    const errors = this.titleErrors()
    const className = errors && errors.length > 0 ? 'invalid' : ''

    return <div className='row'>
      <div className='col s12 input-field'>
        <InputWithLabel id='web_settings_title'
          value={this.state.title}
          label={this.props.t('Title')}
          errors={this.titleErrors()}>
          <input
            type='text'
            disabled={this.props.readOnly}
            onChange={text => this.messageChange(text.target.value, 'title')}
            onBlur={text => this.titleBlur(text.target.value)}
            className={className}
           />
        </InputWithLabel>
      </div>
    </div>
  }

  smsMessageComponent() {
    return <SmsPrompt id='web_settings_sms_message'
      label={this.props.t('SMS message')}
      inputErrors={this.smsMessageErrors()}
      value={this.state.smsMessage}
      originalValue={this.state.smsMessage}
      readOnly={this.props.readOnly}
      onBlur={text => this.smsMessageBlur(text)}
      fixedEndLength={20}
      />
  }

  surveyIsOverMessageComponent() {
    return <MobileWebPrompt id='web_settings_survey_is_over'
      label={this.props.t('"Survey is over" message')}
      inputErrors={this.surveyIsOverMessageErrors()}
      value={this.state.surveyIsOverMessage}
      originalValue={this.state.surveyIsOverMessage}
      onBlur={text => this.surveyIsOverMessageBlur(text)}
      readOnly={this.props.readOnly}
      />
  }

  surveyAlreadyTakenMessageComponent() {
    return <MobileWebPrompt id='web_settings_survey_already_taken'
      label={this.props.t('"Survey already taken" message')}
      inputErrors={this.surveyAlreadyTakenMessageErrors()}
      value={this.state.surveyAlreadyTakenMessage}
      originalValue={this.state.surveyAlreadyTakenMessage}
      onBlur={text => this.surveyAlreadyTakenMessageBlur(text)}
      readOnly={this.props.readOnly}
      />
  }

  colorSelectionComponent() {
    const primaryErrors = this.colorStyleMessageErrors('primary')
    const secondaryErrors = this.colorStyleMessageErrors('secondary')
    const { t } = this.props
    // Default values for mobile web form are #6648a2 and #fb9a00
    const hasPrimaryErrors = primaryErrors && primaryErrors.length > 0
    const hasSecondaryErrors = secondaryErrors && secondaryErrors.length > 0
    const primary = hasPrimaryErrors || !this.state.primaryColor ? '#6648a2' : this.state.primaryColor
    const secondary = hasSecondaryErrors || !this.state.secondaryColor ? '#fb9a00' : this.state.secondaryColor
    const primaryClassName = hasPrimaryErrors ? 'invalid' : ''
    const secondaryClassName = hasSecondaryErrors ? 'invalid' : ''

    return (
      <div className='style row'>
        <h5>{t('Style')}</h5>
        <div className='col s12 m6 l4 web-color input-field'>
          <div className='circle' style={{background: primary}} />
          <InputWithLabel id='web_settings_primary_color' value={this.state.primaryColor} label={t('Primary color')} errors={primaryErrors}>
            <input
              type='text'
              disabled={this.props.readOnly}
              onChange={text => this.messageChange(text.target.value, 'primaryColor')}
              onBlur={text => this.colorSelectionBlur(text.target.value, 'primary')}
              className={primaryClassName}
           />
          </InputWithLabel>
        </div>
        <div className='col s12 m6 l4 web-color input-field'>
          <div className='circle' style={{background: secondary}} />
          <InputWithLabel id='web_settings_secondary_color' value={this.state.secondaryColor} label={t('Secondary color')} errors={secondaryErrors}>
            <input
              type='text'
              disabled={this.props.readOnly}
              onChange={text => this.messageChange(text.target.value, 'secondaryColor')}
              onBlur={text => this.colorSelectionBlur(text.target.value, 'secondary')}
              className={secondaryClassName}
           />
          </InputWithLabel>
        </div>
      </div>
    )
  }

  messageErrors(key) {
    const { questionnaire, errorsByPath } = this.props
    return errorsByPath[`${key}.prompt['${questionnaire.activeLanguage}'].mobileweb`]
  }

  titleErrors() {
    const { questionnaire, errorsByPath } = this.props
    return errorsByPath[`title['${questionnaire.activeLanguage}']`]
  }

  smsMessageErrors() {
    const { errorsByPath } = this.props
    return errorsByPath['mobileWebSmsMessage']
  }

  surveyIsOverMessageErrors() {
    const { errorsByPath } = this.props
    return errorsByPath['mobileWebSurveyIsOverMessage']
  }

  colorStyleMessageErrors(mode) {
    const { errorsByPath } = this.props
    if (mode == 'primary') {
      return errorsByPath['mobileWebColorStyle.primaryColor']
    } else {
      return errorsByPath['mobileWebColorStyle.secondaryColor']
    }
  }

  surveyAlreadyTakenMessageErrors() {
    const { questionnaire, errorsByPath } = this.props
    return errorsByPath[`surveyAlreadyTakenMessage['${questionnaire.activeLanguage}']`]
  }

  hasErrors() {
    return !!this.messageErrors('errorMessage') ||
      !!this.messageErrors('thankYouMessage') ||
      !!this.titleErrors() ||
      !!this.smsMessageErrors() ||
      !!this.surveyIsOverMessageErrors() ||
      !!this.surveyAlreadyTakenMessageErrors() ||
      !!this.colorStyleMessageErrors('primary') ||
      !!this.colorStyleMessageErrors('secondary')
  }

  render() {
    if (this.state.editing) {
      return this.expanded()
    } else {
      return this.collapsed()
    }
  }
}

WebSettings.propTypes = {
  dispatch: PropTypes.any,
  questionnaire: PropTypes.object,
  errorsByPath: PropTypes.object,
  errorMessage: PropTypes.string,
  t: PropTypes.func,
  thankYouMessage: PropTypes.string,
  title: PropTypes.string,
  smsMessage: PropTypes.string,
  surveyIsOverMessage: PropTypes.string,
  surveyAlreadyTakenMessage: PropTypes.string,
  primaryColor: PropTypes.string,
  readOnly: PropTypes.bool
}

const mapStateToProps = (state, ownProps) => {
  const questionnaire = ownProps.questionnaire
  return {
    errorsByPath: state.questionnaire.errorsByPath,
    errorMessage: getPromptMobileWeb(questionnaire.settings.errorMessage, questionnaire.activeLanguage),
    thankYouMessage: getPromptMobileWeb(questionnaire.settings.thankYouMessage, questionnaire.activeLanguage),
    title: (questionnaire.settings.title || {})[questionnaire.activeLanguage] || '',
    smsMessage: questionnaire.settings.mobileWebSmsMessage || '',
    surveyIsOverMessage: questionnaire.settings.mobileWebSurveyIsOverMessage || '',
    surveyAlreadyTakenMessage: (questionnaire.settings.surveyAlreadyTakenMessage || {})[questionnaire.activeLanguage] || '',
    primaryColor: questionnaire.settings.mobileWebColorStyle && questionnaire.settings.mobileWebColorStyle.primaryColor || '',
    secondaryColor: questionnaire.settings.mobileWebColorStyle && questionnaire.settings.mobileWebColorStyle.secondaryColor || ''
  }
}

export default translate()(withQuestionnaire(connect(mapStateToProps)(WebSettings)))
