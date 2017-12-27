// @flow
import * as actions from '../../actions/questionnaire'
import React, { Component } from 'react'
import { connect } from 'react-redux'
import 'materialize-autocomplete'
import { translateLangCode } from '../timezones/util'
import classNames from 'classnames/bind'
import AddLanguage from './AddLanguage'
import { hasErrorsInLanguage } from '../../questionnaireErrors'
import withQuestionnaire from './withQuestionnaire'

type Props = {
  defaultLanguage: string,
  activeLanguage: string,
  languages: string[],
  errors: ValidationError[],
  onRemoveLanguage: Function,
  dispatch: Function,
  readOnly: boolean
};

class LanguagesList extends Component {
  props: Props

  defaultLanguageSelected(lang) {
    const props = this.props
    return (e) => {
      const { dispatch } = props
      dispatch(actions.setDefaultLanguage(lang))
    }
  }

  setActiveLanguage(e, language) {
    const { dispatch } = this.props
    dispatch(actions.setActiveLanguage(language))
  }

  renderLanguageRow(code, name, isDefault = false) {
    const { activeLanguage, readOnly, onRemoveLanguage, errors } = this.props
    const isActiveLanguage = code == activeLanguage
    const buttons = []

    if (isActiveLanguage) {
      buttons.push(<span key='active-mark' className='active-mark'>
        <i className='material-icons'>done</i>
      </span>)
    }

    if (!readOnly && !isActiveLanguage && !isDefault) {
      buttons.push(<span key='remove-language' className='remove-language' onClick={() => onRemoveLanguage(code)}>
        <i className='material-icons'>highlight_off</i>
      </span>)
    }

    if (!readOnly && !isDefault) {
      buttons.push(<span key='set-default-language' className='set-default-language' onClick={this.defaultLanguageSelected(code)}>
        <i className='material-icons'>arrow_upward</i>
      </span>)
    }

    return <li key={code} onClick={e => this.setActiveLanguage(e, code)}
      className={classNames({'active-language': code == activeLanguage, 'tooltip-error': hasErrorsInLanguage(errors, code)})}>
      {buttons}
      <span className='language-name' title={name}>
        {name}
      </span>
    </li>
  }

  render() {
    const { languages, defaultLanguage, readOnly } = this.props

    const LanguageSection = ({title, children}) =>
      <div className='row'>
        <div className='col s12'>
          <p className='grey-text'>{title}:</p>
          <ul className='languages-list'>{children}</ul>
        </div>
      </div>

    let otherLanguages = languages.filter((lang) => lang !== defaultLanguage)
      .map((lang: string) => [lang, translateLangCode(lang)])
      .sort(([c1, n1], [c2, n2]) => n1.localeCompare(n2))
      .map(([code, name]) => this.renderLanguageRow(code, name))

    let otherLanguagesComponent = null
    if (otherLanguages.length != 0) {
      otherLanguagesComponent = <LanguageSection title='Other languages'>{otherLanguages}</LanguageSection>
    }

    return (
      <div className='languages'>
        <LanguageSection title='Primary language'>
          {this.renderLanguageRow(defaultLanguage, translateLangCode(defaultLanguage), true)}
        </LanguageSection>
        {otherLanguagesComponent}
        {readOnly
        ? null
        : <div className='row'>
          <AddLanguage />
        </div>
        }
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  defaultLanguage: ownProps.questionnaire.defaultLanguage,
  activeLanguage: ownProps.questionnaire.activeLanguage,
  languages: ownProps.questionnaire.languages,
  errors: state.questionnaire.errors
})

export default withQuestionnaire(connect(mapStateToProps)(LanguagesList))
