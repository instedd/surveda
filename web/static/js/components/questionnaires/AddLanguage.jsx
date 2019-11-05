import * as actions from '../../actions/questionnaire'
import React, { Component, PropTypes } from 'react'
import { Autocomplete } from '../ui'
import iso6393 from 'iso-639-3'
import 'materialize-autocomplete'
import withQuestionnaire from './withQuestionnaire'
import { translate } from 'react-i18next'

class AddLanguage extends Component {
  constructor(props) {
    super(props)
    this.state = {
      editing: false
    }
  }

  startEdit() {
    if (this.state.editing) return

    this.setState({editing: true})
  }

  endEdit(e) {
    if (this.refs.autocomplete.clickingAutocomplete) return

    this.setState({editing: false})
  }

  autocompleteGetData(value, callback) {
    const { questionnaire } = this.props
    const idForLanguange = (lang) => lang.iso6391 ? lang.iso6391 : lang.iso6393
    const matchesLanguage = (value, lang) => (lang.text.indexOf(value) !== -1 || lang.text.toLowerCase().indexOf(value) !== -1)

    let languagesOptions = iso6393
        .filter(lang => lang.type == "living" && lang.iso6392T != null)
        .map((lang) => ({'id': idForLanguange(lang), 'text': lang.name}))

    // Don't show languages that are already selected
    languagesOptions = languagesOptions.filter((lang) =>
          (questionnaire.languages || []).indexOf(lang.id) == -1 && questionnaire.defaultLanguage !== lang)

    const matchingOptions = languagesOptions.filter((lang) => matchesLanguage(value.toLowerCase(), lang))
    callback(value, matchingOptions)
  }

  autocompleteOnSelect(item) {
    const { dispatch } = this.props
    this.endEdit()
    dispatch(actions.addLanguage(item.id))
    $(this.refs.languageInput).val('')
  }

  render() {
    const { t } = this.props
    if (!this.state.editing) {
      return (
        <a className='btn-icon-grey' onClick={e => this.startEdit(e)}>
          <i className='material-icons'>add</i>
          <span>{t('Add Language')}</span>
        </a>
      )
    } else {
      return (
        <div className='input-field language-selection'>
          <input type='text' ref='languageInput' id='languageInput' autoComplete='off' className='autocomplete' placeholder={t('Start typing a language')} onBlur={e => this.endEdit(e)} />
          <Autocomplete
            getInput={() => this.refs.languageInput}
            getData={(value, callback) => this.autocompleteGetData(value, callback)}
            onSelect={(item) => this.autocompleteOnSelect(item)}
            showOnClick
            className='language-dropdown'
            ref='autocomplete'
            />
        </div>
      )
    }
  }

  componentDidUpdate() {
    if (this.refs.languageInput) {
      this.refs.languageInput.focus()
    }
  }
}

AddLanguage.propTypes = {
  questionnaire: PropTypes.object,
  t: PropTypes.func,
  dispatch: PropTypes.func
}

export default translate()(withQuestionnaire(AddLanguage))
