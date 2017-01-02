import * as actions from '../../actions/questionnaire'
import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import 'materialize-autocomplete'
import iso6393 from 'iso-639-3'
import AddLanguage from './AddLanguage'
import classNames from 'classnames/bind'

class LanguagesList extends Component {

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
    const { questionnaire, onRemoveLanguage } = this.props

    if (!questionnaire) {
      return <div>Loading...</div>
    }

    let defaultLanguage = questionnaire.defaultLanguage
    let activeLanguage = questionnaire.activeLanguage

    let otherLangugages = questionnaire.languages.filter((lang) => lang !== defaultLanguage)
    otherLangugages = otherLangugages.map((lang) => [lang, this.translateLangCode(lang)])
    otherLangugages = otherLangugages.sort((l1, l2) => (l1[1] <= l2[1]) ? -1 : 1)
    otherLangugages = otherLangugages.map((lang) =>
      <li key={lang[0]} className={classNames({'active-language': lang[0] == activeLanguage})}>
        <span className='remove-language' onClick={() => onRemoveLanguage(lang[0])}>
          <i className='material-icons'>highlight_off</i>
        </span>
        <span className='language-name' title={this.translateLangCode(lang[0])}>
          {this.translateLangCode(lang[0])}
        </span>
        <span className='set-default-language' onClick={this.defaultLanguageSelected(lang[0])}>
          <i className='material-icons'>arrow_upward</i>
        </span>
        <span href='#' className='right-arrow' onClick={e => this.setActiveLanguage(e, lang[0])}>
          <i className='material-icons'>keyboard_arrow_right</i>
        </span>
      </li>
      )

    let otherLangugagesComponent = null
    if (otherLangugages.length != 0) {
      otherLangugagesComponent = (
        <div className='row'>
          <div className='col s12'>
            <p className='grey-text'>Other languages:</p>
            <ul className='other-languages-list'>
              {otherLangugages}
            </ul>
          </div>
        </div>
        )
    }

    return (
      <div className='languages'>
        <div className='row'>
          <div className='col s12'>
            <p className='grey-text'>Primary language:</p>
            <ul className={classNames({'selected-language': true, 'active-language': activeLanguage == defaultLanguage})}>
              <li>
                <span>{this.translateLangCode(defaultLanguage)}</span>
                <span href='#' className='right-arrow' onClick={e => this.setActiveLanguage(e, defaultLanguage)}>
                  <i className='material-icons'>keyboard_arrow_right</i>
                </span>
              </li>
            </ul>
          </div>
        </div>
        {otherLangugagesComponent}
        <div className='row'>
          <AddLanguage />
        </div>
      </div>
    )
  }
}

LanguagesList.propTypes = {
  questionnaire: PropTypes.object,
  onRemoveLanguage: PropTypes.func
}

const mapStateToProps = (state, ownProps) => ({
  questionnaire: state.questionnaire.data
})

export default connect(mapStateToProps)(LanguagesList)
