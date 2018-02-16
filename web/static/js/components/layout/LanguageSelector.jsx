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

  render() {
    const { i18n } = this.props
    const currentLanguage = i18n.language
    return (
      <ul>
        <li>
          <Dropdown label='Select Language' icon='language' >
            <DropdownDivider />
            <DropdownItem>
              <i className='material-icons left' style={{opacity: `${currentLanguage == 'en' ? 1 : 0}`}} >done</i>
              <a onClick={() => this.changeLanguage('en')}>English</a>
            </DropdownItem>
            <DropdownItem>
              <i className='material-icons left' style={{opacity: `${currentLanguage == 'es' ? 1 : 0}`}} >done</i>
              <a onClick={() => this.changeLanguage('es')}>Español</a>
            </DropdownItem>
            <DropdownItem>
              <i className='material-icons left' style={{opacity: `${currentLanguage == 'fr' ? 1 : 0}`}} >done</i>
              <a onClick={() => this.changeLanguage('fr')}>Français</a>
            </DropdownItem>
          </Dropdown>
        </li>
      </ul>
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
