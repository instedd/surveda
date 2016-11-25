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

  render() {
    const { questionnaire } = this.props

    if (!questionnaire) {
      return <div>Loading...</div>
    }

    const list =  questionnaire.languages.map((lang) =>
        <div onClick={this.defaultLanguageSelected(lang)}>
            {lang}
          </div>
        )

    return (
      <div>
        {list}
      </div>
    )
  }

}

const mapStateToProps = (state, ownProps) => ({
  questionnaire: state.questionnaire.data
})

export default connect(mapStateToProps)(LanguagesList)
