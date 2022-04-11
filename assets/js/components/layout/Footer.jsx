import React from "react"
import { config } from "../../config"
import LanguageSelector from "./LanguageSelector"
import { translate } from "react-i18next"

export default translate()(({ t }) => (
  <footer>
    <div className="row">
      <div className="col s12 m7">
        InSTEDD© - GPLv3 - Developed in collaboration with Bloomberg Philanthropies, CDC, and RTI
        International.
      </div>
      <div className="col s12 m5 right-align">
        <LanguageSelector className="languageSelector" />
        <span className="grey-text lighten2">
          {t("Version: {{version}}", { version: config.version })}
        </span>
      </div>
    </div>
  </footer>
))
