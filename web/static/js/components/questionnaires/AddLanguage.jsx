import * as actions from '../../actions/questionnaire'
import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import 'materialize-autocomplete'

class AddLanguage extends Component {

  languageAdded(context) {
    return (language) => {
      const { dispatch } = context.props
      dispatch(actions.addLanguage(language.id))
      $(context.refs.languageInput).val('')
    }
  }

  render() {
    const { questionnaire } = this.props
    return (
      <div className='row'>
        <div className='col s12'>
          <div className='row'>
            <div className='input-field col s12'>
              <input type='text' ref='languageInput' id='languageInput' autocomplete='off' />
              <ul style={{background: '#bbb'}} ref='languagesDropdown' id='languageInput' />
              <label htmlFor='singleInput'>Add language</label>
            </div>
          </div>
        </div>
      </div>
    )
  }

  componentDidMount() {
    const thisContext = this
    const languageAdded = this.languageAdded
    const languageInput = this.refs.languageInput
    const languagesDropdown = this.refs.languagesDropdown

    const idForLanguange = (lang) => lang.iso6391 ? lang.iso6391 : lang.iso6393
    const matchesLanguage = (value, lang) => (lang.text.indexOf(value) !== -1 || lang.text.toLowerCase().indexOf(value) !== -1)

    $(document).ready(function() {
      $(languageInput).materialize_autocomplete({
        limit: 100,
        multiple: {
          enable: false
        },
        dropdown: {
          el: languagesDropdown,
          itemTemplate: '<li class="ac-item" data-id="<%= item.id %>" data-text=\'<%= item.text %>\'><%= item.text %></li>'
        },
        onSelect: thisContext.languageAdded(thisContext),
        getData: function(value, callback) {
          const iso6393 = require('iso-639-3')
          const languagesOptions = iso6393.map((lang) => ({'id': idForLanguange(lang), 'text': lang.name}))
          const matchingOptions = languagesOptions.filter((lang) => matchesLanguage(value.toLowerCase(), lang))
          callback(value, matchingOptions)
        }
      })
    })
  }
}

const mapStateToProps = (state, ownProps) => ({
  questionnaire: state.questionnaire
})

export default connect(mapStateToProps)(AddLanguage)
