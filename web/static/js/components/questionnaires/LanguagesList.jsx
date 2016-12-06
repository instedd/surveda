import * as actions from '../../actions/questionnaire'
import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import 'materialize-autocomplete'
import iso6393 from 'iso-639-3'
import AddLanguage from './AddLanguage'

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

  removeLanguage(lang) {
    const props = this.props
    return (e) => {
      const { dispatch } = props
      dispatch(actions.removeLanguage(lang))
    }
  }

  render() {
    const { questionnaire } = this.props

    if (!questionnaire) {
      return <div>Loading...</div>
    }

    let otherLangugages = questionnaire.languages.filter((lang) => lang !== questionnaire.defaultLanguage)
    otherLangugages = otherLangugages.map((lang) => [lang, this.translateLangCode(lang)])
    otherLangugages = otherLangugages.sort((l1, l2) => (l1[1] <= l2[1]) ? -1 : 1)
    otherLangugages = otherLangugages.map((lang) =>
      <li key={lang[0]}>
        <span className='remove-language' onClick={this.removeLanguage(lang[0])}>
          <i className='material-icons'>highlight_off</i>
        </span>
        <span className='language-name' title={this.translateLangCode(lang[0])}>
          {this.translateLangCode(lang[0])}
        </span>
        <span className='set-default-language' onClick={this.defaultLanguageSelected(lang[0])}>
          <i className='material-icons'>arrow_upward</i>
        </span>
        <span className='right-arrow'>
          <i className='material-icons'>keyboard_arrow_right</i>
        </span>
      </li>
      )

    let otherLangugagesComponent = null
    if (otherLangugages.length != 0) {
      otherLangugagesComponent = (
        <div className="row">
          <div className="col s12">
            <p className="grey-text">Other languages:</p>
            <ul className='other-languages-list'>
              {otherLangugages}
            </ul>
          </div>
        </div>
        )
    }

    return (
      <div className="languages">
        <div className="row">
          <div className="col s12">
            <p className="grey-text">Primary language:</p>
            <ul className='selected-language'>
              <li>
                <span>{this.translateLangCode(questionnaire.defaultLanguage)}</span>
                <i className='material-icons'>keyboard_arrow_right</i>
              </li>
            </ul>
          </div>
        </div>
        {otherLangugagesComponent}
        <div className="row">
          <AddLanguage />
        </div>
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  questionnaire: state.questionnaire.data
})

export default connect(mapStateToProps)(LanguagesList)
