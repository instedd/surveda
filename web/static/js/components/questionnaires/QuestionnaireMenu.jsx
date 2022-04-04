import React, { PropTypes, Component } from "react"
import { bindActionCreators } from "redux"
import { connect } from "react-redux"
import { withRouter } from "react-router"
import * as questionnaireActions from "../../actions/questionnaire"
import * as uiActions from "../../actions/ui"
import { csvForTranslation, csvTranslationFilename } from "../../reducers/questionnaire"
import csvString from "csv-string"
import * as language from "../../language"
import * as routes from "../../routes"
import { Dropdown, DropdownItem } from "../ui"
import withQuestionnaire from "./withQuestionnaire"
import { translate } from "react-i18next"

class QuestionnaireMenu extends Component {
  static propTypes = {
    questionnaire: PropTypes.object,
    questionnaireActions: PropTypes.object.isRequired,
    uiActions: PropTypes.object.isRequired,
    t: PropTypes.func,
    readOnly: PropTypes.bool,
  }

  handleSubmit(newName) {
    const { questionnaire, questionnaireActions } = this.props
    if (questionnaire.name == newName) return

    questionnaireActions.changeName(newName)
  }

  buildCsvLink() {
    const data = csvForTranslation(this.props.questionnaire)
    const csvData = csvString.stringify(data)
    return "data:text/csv;charset=utf-8," + encodeURIComponent(csvData)
  }

  openUploadCsvDialog(e) {
    e.preventDefault()

    $("#questionnaire_file_upload").trigger("click")
  }

  uploadCsv(e) {
    e.preventDefault()

    const { t } = this.props

    let files = e.target.files
    if (files.length < 1) return

    let file = files[0]
    let reader = new FileReader()
    reader.onload = (e2) => {
      let contents = e2.target.result
      let csv = csvString.parse(contents)

      // Do some validations before uploading the CSV
      if (csv.length == 0) {
        window.Materialize.toast(t("Error: CSV is empty"), 5000)
        return
      }

      let primaryLanguageCode = this.props.questionnaire.defaultLanguage
      let primaryLanguageName = language.codeToName(primaryLanguageCode)
      if (!primaryLanguageName) {
        window.Materialize.toast(
          `${t("Error: primary language name not found for code")} ${primaryLanguageCode}`,
          5000
        )
        return
      }

      let headers = csv[0]
      let defaultLanguageIndex = headers.indexOf(primaryLanguageName)
      if (defaultLanguageIndex == -1) {
        window.Materialize.toast(
          `${t(
            "Error: CSV doesn't have a header for the primary language"
          )} '${primaryLanguageName}'`,
          5000
        )
        return
      }

      this.props.questionnaireActions.uploadCsvForTranslation(csv)

      window.Materialize.toast(
        `${t("CSV uploaded successfully! {{count}} key was updated", {
          count: csv.length - 1,
        })} ${t("in {{count}} language", { count: headers.length - 1 })}`,
        5000
      )
    }
    reader.readAsText(file)

    // Make sure to clear the input's value so a same file
    // can be uploaded multiple times
    e.target.value = null
  }

  exportZip(e) {
    e.preventDefault()

    const { questionnaire } = this.props
    window.location = routes.exportQuestionnaireZip(questionnaire.projectId, questionnaire.id)
  }

  openImportZipDialog(e) {
    e.preventDefault()

    // This is a workaround for issue https://github.com/instedd/ask/issues/908
    //
    // On Chrome, when a file input has an accept=".zip" attributes one can
    // click multiple times on it and it will open several dialogs (one
    // after another). This doesn't happen with other values for the accept
    // attribute.
    //
    // What we do is we prevent the user from triggering another click
    // until 2 seconds have passed. 2 seconds is big enough for the user
    // to click the link, wait for the dialog to open, maybe cancel it,
    // and then want to click the link again. This way accidental multiple
    // clicks are prevented.
    if (this.preventSecondImportZipDialog) return
    this.preventSecondImportZipDialog = true
    setTimeout(() => {
      this.preventSecondImportZipDialog = false
    }, 2000)

    $("#questionnaire_import_zip").trigger("click")
  }

  importZip(e) {
    e.preventDefault()

    let files = e.target.files
    if (files.length != 1) return

    const { questionnaire, uiActions } = this.props

    uiActions.importQuestionnaire(questionnaire.projectId, questionnaire.id, files[0])

    // Make sure to clear the input's value so a same file
    // can be uploaded multiple times
    e.target.value = null
  }

  render() {
    const { questionnaire, readOnly, t } = this.props

    return (
      <Dropdown
        className="title-options options questionnaire-menu"
        dataBelowOrigin={false}
        label={<i className="material-icons">more_vert</i>}
      >
        <DropdownItem className="dots">
          <i className="material-icons">more_vert</i>
        </DropdownItem>
        <DropdownItem>
          <a href="#" onClick={(e) => this.exportZip(e)}>
            <i className="material-icons">file_download</i>
            <span>{t("Export questionnaire")}</span>
          </a>
        </DropdownItem>
        {!readOnly ? (
          <DropdownItem>
            <input
              id="questionnaire_import_zip"
              type="file"
              accept=".zip"
              style={{ display: "none" }}
              onChange={(e) => this.importZip(e)}
            />
            <a href="#" onClick={(e) => this.openImportZipDialog(e)}>
              <i className="material-icons">file_upload</i>
              <span>{t("Import questionnaire")}</span>
            </a>
          </DropdownItem>
        ) : (
          ""
        )}
        {!readOnly ? (
          <DropdownItem>
            <a href={this.buildCsvLink()} download={csvTranslationFilename(questionnaire)}>
              <i className="material-icons">file_download</i>
              <span>{t("Download contents as CSV")}</span>
            </a>
          </DropdownItem>
        ) : (
          ""
        )}
        {!readOnly ? (
          <DropdownItem>
            <input
              id="questionnaire_file_upload"
              type="file"
              accept=".csv"
              style={{ display: "none" }}
              onChange={(e) => this.uploadCsv(e)}
            />
            <a href="#" onClick={(e) => this.openUploadCsvDialog(e)}>
              <i className="material-icons">file_upload</i>
              <span>{t("Upload contents as CSV")}</span>
            </a>
          </DropdownItem>
        ) : (
          ""
        )}
      </Dropdown>
    )
  }
}

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch),
  uiActions: bindActionCreators(uiActions, dispatch),
})

export default translate()(
  withQuestionnaire(withRouter(connect(null, mapDispatchToProps)(QuestionnaireMenu)))
)
