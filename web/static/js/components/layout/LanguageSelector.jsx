import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as userSettingsActions from '../../actions/userSettings'
import { Dropdown, DropdownItem, DropdownDivider } from '../ui'
import { translate } from 'react-i18next'

class LanguageSelector extends Component {
  componentWillMount() {
    const { dispatch } = this.props
    dispatch(userSettingsActions.fetchSettings())
  }

  changeLanguage(language) {
    const { dispatch, i18n } = this.props
    dispatch(userSettingsActions.changeLanguage(language))
    i18n.changeLanguage(language)
  }

  languageNameFromCode(code) {
    switch (code) {
      case 'en':
        return 'English (en)'
      case 'es':
        return 'Español (es)'
      case 'fr':
        return 'Français (fr)'
      default:
        return ''
    }
  }

  render() {
    const { i18n } = this.props
    const currentLanguage = i18n.language

    return (
          <Dropdown className={this.props.className} label={this.languageNameFromCode(currentLanguage)} icon='language' iconLeft >
            <DropdownDivider />
            <DropdownItem>
              <a onClick={() => this.changeLanguage('en')}>
                <i className='material-icons' style={{opacity: `${currentLanguage == 'en' ? 1 : 0}`}} >done</i>
                English
                <span className='lang'>en</span>
              </a>
            </DropdownItem>
            <DropdownItem>
              <a onClick={() => this.changeLanguage('es')}>
                <i className='material-icons' style={{opacity: `${currentLanguage == 'es' ? 1 : 0}`}} >done</i>
                Español
                <span className='lang'>es</span>
              </a>
            </DropdownItem>
            <DropdownItem>
              <a onClick={() => this.changeLanguage('fr')}>
                <i className='material-icons' style={{opacity: `${currentLanguage == 'fr' ? 1 : 0}`}} >done</i>
                Français
                <span className='lang'>fr</span>
              </a>
            </DropdownItem>
          </Dropdown>
    )
  }
}

LanguageSelector.propTypes = {
  userSettings: PropTypes.object,
  i18n: PropTypes.object,
  dispatch: PropTypes.any

}
const mapStateToProps = (state, ownProps) => ({
  userSettings: state.userSettings
})

export default translate()(connect(mapStateToProps)(LanguageSelector))
