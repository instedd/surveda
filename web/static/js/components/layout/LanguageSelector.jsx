import React, { Component, PropTypes } from "react"
import { connect } from "react-redux"
import * as userSettingsActions from "../../actions/userSettings"
import { Dropdown, DropdownItem, DropdownDivider } from "../ui"
import { translate } from "react-i18next"

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
      case "en":
        return "English"
      case "es":
        return "Español"
      case "fr":
        return "Français"
      default:
        return ""
    }
  }

  render() {
    const { i18n } = this.props
    const currentLanguage = i18n.language

    return (
      <Dropdown
        className={"languageSelector"}
        label={`${this.languageNameFromCode(currentLanguage)} (${currentLanguage})`}
        icon="language"
        iconLeft
      >
        <DropdownDivider />
        <LanguageItem languageCode="en" currentLanguage={currentLanguage} langSelector={this} />
        <LanguageItem languageCode="es" currentLanguage={currentLanguage} langSelector={this} />
        <LanguageItem languageCode="fr" currentLanguage={currentLanguage} langSelector={this} />
      </Dropdown>
    )
  }
}

const LanguageItem = ({ languageCode, currentLanguage, langSelector }) => (
  <DropdownItem>
    <a onClick={() => langSelector.changeLanguage(languageCode)}>
      <i
        className="material-icons"
        style={{ opacity: `${currentLanguage == languageCode ? 1 : 0}` }}
      >
        done
      </i>
      {langSelector.languageNameFromCode(languageCode)}
      <span className="lang">{languageCode}</span>
    </a>
  </DropdownItem>
)

LanguageItem.propTypes = {
  langSelector: PropTypes.object,
  languageCode: PropTypes.string,
  languageName: PropTypes.string,
  currentLanguage: PropTypes.string,
}

LanguageSelector.propTypes = {
  userSettings: PropTypes.object,
  i18n: PropTypes.object,
  dispatch: PropTypes.any,
}
const mapStateToProps = (state, ownProps) => ({
  userSettings: state.userSettings,
})

export default translate()(connect(mapStateToProps)(LanguageSelector))
