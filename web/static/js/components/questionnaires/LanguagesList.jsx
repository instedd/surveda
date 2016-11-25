import * as actions from '../../actions/questionnaire'
import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import 'materialize-autocomplete'

class LanguagesList extends Component {

  defaultLanguageSelected(lang){
    const props = this.props
    return (e) => {
      const { dispatch } = props
      dispatch(actions.setDefaultLanguage(lang))
    }
  }

  translateLangCode(code) {
    const iso6393 = require('iso-639-3')
    const language = iso6393.find((lang) => lang.iso6391 == code || lang.iso6393 == code)
    return language.name
  }

  removeLanguage(lang){
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

    let otherLangugages =  questionnaire.languages.filter((lang) => lang !== questionnaire.defaultLanguage)
    otherLangugages =  otherLangugages.map((lang) => [lang, this.translateLangCode(lang)])
    otherLangugages = otherLangugages.sort((l1, l2) => (l1[1] <= l2[1]) ? -1 : 1)
    otherLangugages =  otherLangugages.map((lang) =>
        <div>
          <span onClick={this.removeLanguage(lang[0])}> (x) </span>
          <span onClick={this.defaultLanguageSelected(lang[0])}>
              {this.translateLangCode(lang[0])}
          </span>
        </div>
      )

    return (
      <div>
        <div>
        Primary language:
        <div>
          {this.translateLangCode(questionnaire.defaultLanguage)}
        </div>
      </div>
        <div>
          <div>
            Other languages:
          </div>
          {otherLangugages}
        </div>
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  questionnaire: state.questionnaire.data
})

export default connect(mapStateToProps)(LanguagesList)
