import * as actions from '../../actions/questionnaire'
import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import iso6393 from 'iso-639-3'
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
    return (
      <div className='input-field language-selection'>
        <input type='text' ref='languageInput' id='languageInput' autoComplete='off' className='autocomplete' />
        <label htmlFor='singleInput'><i className='material-icons v-middle'>add</i> Add language</label>
        <ul className='autocomplete-content dropdown-content language-dropdown' ref='languagesDropdown' id='languageInput' />
      </div>
    )
  }

  componentDidMount() {
    const { questionnaire } = this.props
    const thisContext = this
    const languageAdded = this.languageAdded
    const languageInput = this.refs.languageInput
    const languagesDropdown = this.refs.languagesDropdown

    const idForLanguange = (lang) => lang.iso6391 ? lang.iso6391 : lang.iso6393
    const matchesLanguage = (value, lang) => (lang.text.indexOf(value) !== -1 || lang.text.toLowerCase().indexOf(value) !== -1)

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
        const languagesOptions = iso6393.map((lang) => ({'id': idForLanguange(lang), 'text': lang.name}))
        // Next step: Don't show options that have been already selected
        // languagesOptions = languagesOptions.filter((lang) => questionnaire.languages.indexOf(lang.id) == -1 && questionnaire.defaultLanguage !== lang)
        const matchingOptions = languagesOptions.filter((lang) => matchesLanguage(value.toLowerCase(), lang))
        callback(value, matchingOptions)
      }
    })
  }
}

const mapStateToProps = (state, ownProps) => ({
  questionnaire: state.questionnaire.data
})

export default connect(mapStateToProps)(AddLanguage)
