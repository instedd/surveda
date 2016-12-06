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
    this.handleClick = this.handleClick.bind(this)
    this.endEdit = this.endEdit.bind(this)
  }

  handleClick() {
    if (!this.state.editing) {
      this.setState({editing: !this.state.editing})
    }
  }

  endEdit(e) {
    const context = this
    // todo: Avoid using timeout
    setTimeout(
      () => context.setState({editing: false}), 100
    )
  }

  languageAdded(context) {
    return (language) => {
      const { dispatch } = context.props
      context.endEdit()
      dispatch(actions.addLanguage(language.id))
      $(context.refs.languageInput).val('')
    }
  }

  render() {
    if (!this.state.editing) {
      return (
        <a className='add-language' onClick={this.handleClick}>
          <i className='material-icons'>add</i>
          <span>Add Language</span>
        </a>
      )
    } else {
      return (
        <div className='input-field language-selection'>
          <input type='text' ref='languageInput' id='languageInput' autoComplete='off' className='autocomplete' placeholder='Start typing a language' onBlur={this.endEdit}/>
          <ul className='autocomplete-content dropdown-content language-dropdown' ref='languagesDropdown' id='languageInput' />
        </div>
      )
    }
  }

  componentDidUpdate() {
    const thisContext = this
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
    if (this.refs.languageInput) {
      this.refs.languageInput.focus()
    }
  }
}

const mapStateToProps = (state, ownProps) => ({
  questionnaire: state.questionnaire.data
})

export default connect(mapStateToProps)(AddLanguage)
