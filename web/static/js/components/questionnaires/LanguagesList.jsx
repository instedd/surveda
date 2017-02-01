// @flow
import * as actions from '../../actions/questionnaire'
import React, { Component } from 'react'
import { connect } from 'react-redux'
import 'materialize-autocomplete'
import iso6393 from 'iso-639-3'
import classNames from 'classnames/bind'
import { langHasErrors } from '../../questionnaireErrors'
import AddLanguage from './AddLanguage'

type Props = {
  defaultLanguage: string,
  activeLanguage: string,
  languages: string[],
  loading: boolean,
  langHasErrors: (lang: string) => boolean,
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

  translateLangCode(code) {
    const language = iso6393.find((lang) => lang.iso6391 == code || lang.iso6393 == code)
    return language.name
  }

  setActiveLanguage(e, language) {
    const { dispatch } = this.props
    dispatch(actions.setActiveLanguage(language))
  }

  render() {
    const { loading, languages, defaultLanguage, activeLanguage, onRemoveLanguage, langHasErrors, readOnly } = this.props

    if (loading) {
      return <div>Loading...</div>
    }

    let otherLanguages = languages.filter((lang) => lang !== defaultLanguage)
    otherLanguages = otherLanguages.map((lang: string) => [lang, this.translateLangCode(lang)])
    otherLanguages = otherLanguages.sort((l1, l2) => (l1[1] <= l2[1]) ? -1 : 1)
    otherLanguages = otherLanguages.map((lang) =>
      <li key={lang[0]} className={classNames({'active-language': lang[0] == activeLanguage, 'tooltip-error': langHasErrors(lang[0])})}>
        {readOnly
        ? null
        : <div>
          <span className='remove-language' onClick={() => onRemoveLanguage(lang[0])}>
            <i className='material-icons'>highlight_off</i>
          </span>
          <span className='set-default-language' onClick={this.defaultLanguageSelected(lang[0])}>
            <i className='material-icons'>arrow_upward</i>
          </span>
        </div>
        }
        <span className='language-name' title={this.translateLangCode(lang[0])}>
          {this.translateLangCode(lang[0])}
        </span>
        <span href='#' className='right-arrow' onClick={e => this.setActiveLanguage(e, lang[0])}>
          <i className='material-icons'>keyboard_arrow_right</i>
        </span>
      </li>
      )

    let otherLanguagesComponent = null
    if (otherLanguages.length != 0) {
      otherLanguagesComponent = (
        <div className='row'>
          <div className='col s12'>
            <p className='grey-text'>Other languages:</p>
            <ul className='other-languages-list'>
              {otherLanguages}
            </ul>
          </div>
        </div>
        )
    }

    const defaultLanguageClassnames = classNames({
      'selected-language': true,
      'active-language': activeLanguage == defaultLanguage
    })

    return (
      <div className='languages'>
        <div className='row'>
          <div className='col s12'>
            <p className='grey-text'>Primary language:</p>
            <ul className={defaultLanguageClassnames}>
              <li className={classNames({'tooltip-error': langHasErrors(defaultLanguage)})}>
                <span>{this.translateLangCode(defaultLanguage)}</span>
                <span href='#' className='right-arrow' onClick={e => this.setActiveLanguage(e, defaultLanguage)}>
                  <i className='material-icons'>keyboard_arrow_right</i>
                </span>
              </li>
            </ul>
          </div>
        </div>
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
  defaultLanguage: (state.questionnaire.data || {}).defaultLanguage,
  activeLanguage: (state.questionnaire.data || {}).activeLanguage,
  languages: (state.questionnaire.data || {}).languages,
  loading: !state.questionnaire.data,
  langHasErrors: langHasErrors(state.questionnaire)
})

export default connect(mapStateToProps)(LanguagesList)
