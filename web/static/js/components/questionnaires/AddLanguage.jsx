import * as actions from '../../actions/questionnaire'
import React, { Component } from 'react'
import { connect } from 'react-redux'
import iso6393 from 'iso-639-3'
import 'materialize-autocomplete'

class AddLanguage extends Component {
  constructor(props) {
    super(props)
    this.state = {
      editing: false
    }

    // We want to close the languages popup when clicking outside
    // the text input. However, materialize_autocomplete triggers
    // the selection on the onClick event, so on the mouseDown event
    // the popup will be closed. To prevent this, we add an onMouseDown
    // event on the <ul> of the popup and set this flag to true.
    // So, when we click on the popup the popup won't be closed until
    // the language is added (languageAdded handler). Clicking outside
    // of the popup will close the popup correctly.
    this.preventClose = false
  }

  handleClick() {
    if (!this.state.editing) {
      this.setState({editing: !this.state.editing})
    }
  }

  endEdit(e) {
    const context = this
    if (!this.preventClose) {
      context.setState({editing: false})
    }
  }

  languageAdded(context) {
    return (language) => {
      const { dispatch } = context.props
      this.preventClose = false
      context.endEdit()
      dispatch(actions.addLanguage(language.id))
      $(context.refs.languageInput).val('')
    }
  }

  preventCloseCallback(e) {
    this.preventClose = true
  }

  render() {
    if (!this.state.editing) {
      return (
        <a className='btn-icon-grey' onClick={e => this.handleClick(e)}>
          <i className='material-icons'>add</i>
          <span>Add Language</span>
        </a>
      )
    } else {
      return (
        <div className='input-field language-selection'>
          <input type='text' ref='languageInput' id='languageInput' autoComplete='off' className='autocomplete' placeholder='Start typing a language' onBlur={e => this.endEdit(e)} />
          <ul className='autocomplete-content dropdown-content language-dropdown' ref='languagesDropdown' id='languageInput' onMouseDown={(e) => this.preventCloseCallback(e)} />
        </div>
      )
    }
  }

  componentDidUpdate() {
    const thisContext = this
    const { questionnaire } = this.props
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
        let languagesOptions = iso6393.map((lang) => ({'id': idForLanguange(lang), 'text': lang.name}))

        // Don't show languages that are already selected
        languagesOptions = languagesOptions.filter((lang) =>
          (questionnaire.languages || []).indexOf(lang.id) == -1 && questionnaire.defaultLanguage !== lang)

        const matchingOptions = languagesOptions.filter((lang) => matchesLanguage(value.toLowerCase(), lang))
        callback(value, matchingOptions)
      }
    })
    if (this.refs.languageInput) {
      this.refs.languageInput.focus()
    }
  }
}

const mapStateToProps = (state, ownProps) => ({
  questionnaire: state.questionnaire.data
})

export default connect(mapStateToProps)(AddLanguage)
