import React, { PropTypes, Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as questionnaireActions from '../../actions/questionnaire'
import * as uiActions from '../../actions/ui'
import { csvForTranslation, csvTranslationFilename } from '../../reducers/questionnaire'
import csvString from 'csv-string'
import * as language from '../../language'
import * as routes from '../../routes'
import * as api from '../../api'
import { ConfirmationModal, Dropdown, DropdownItem } from '../ui'
import withQuestionnaire from './withQuestionnaire'

class QuestionnaireMenu extends Component {
  static propTypes = {
    questionnaire: PropTypes.object,
    questionnaireActions: PropTypes.object.isRequired,
    uiActions: PropTypes.object.isRequired,
    readOnly: PropTypes.bool
  }

  handleSubmit(newName) {
    const { questionnaire, questionnaireActions } = this.props
    if (questionnaire.name == newName) return

    questionnaireActions.changeName(newName)
  }

  downloadCsv(e) {
    e.preventDefault()

    const { questionnaire } = this.props

    const data = csvForTranslation(questionnaire)
    let csvContent = 'data:text/csv;charset=utf-8,'
    csvContent += csvString.stringify(data)
    const encodedUri = encodeURI(csvContent)
    const a = document.createElement('a')
    a.href = encodedUri
    a.download = csvTranslationFilename(questionnaire)
    a.click()
  }

  openUploadCsvDialog(e) {
    e.preventDefault()

    $('#questionnaire_file_upload').trigger('click')
  }

  uploadCsv(e) {
    e.preventDefault()

    let files = e.target.files
    if (files.length < 1) return

    let file = files[0]
    let reader = new FileReader()
    reader.onload = (e2) => {
      let contents = e2.target.result
      let csv = csvString.parse(contents)

      // Do some validations before uploading the CSV
      if (csv.length == 0) {
        window.Materialize.toast('Error: CSV is empty', 5000)
        return
      }

      let primaryLanguageCode = this.props.questionnaire.defaultLanguage
      let primaryLanguageName = language.codeToName(primaryLanguageCode)
      if (!primaryLanguageName) {
        window.Materialize.toast(`Error: primary language name not found for code ${primaryLanguageCode}`, 5000)
        return
      }

      let headers = csv[0]
      let defaultLanguageIndex = headers.indexOf(primaryLanguageName)
      if (defaultLanguageIndex == -1) {
        window.Materialize.toast(`Error: CSV doesn't have a header for the primary language '${primaryLanguageName}'`, 5000)
        return
      }

      this.props.questionnaireActions.uploadCsvForTranslation(csv)

      window.Materialize.toast(`CSV uploaded successfully! ${csv.length - 1} keys were updated in ${headers.length - 1} languages`, 5000)
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
    setTimeout(() => { this.preventSecondImportZipDialog = false }, 2000)

    $('#questionnaire_import_zip').trigger('click')
  }

  importZip(e) {
    e.preventDefault()

    let files = e.target.files
    if (files.length != 1) return

    const { questionnaire } = this.props
    const importModal = this.refs.importModal

    api.importQuestionnaireZip(questionnaire.projectId, questionnaire.id, files)
    .then(response => {
      const questionnaire = response.entities.questionnaires[response.result]
      // Make sure to deselect any step before receiving the questionnaire
      this.props.uiActions.deselectStep()
      this.props.uiActions.deselectQuotaCompletedStep()
      this.props.questionnaireActions.receive(questionnaire)
      importModal.close()
    })

    // Make sure to clear the input's value so a same file
    // can be uploaded multiple times
    e.target.value = null

    importModal.open({
      modalText: <div>
        <p>Your questionnaire is being imported, please wait...</p>
        <div className='center-align'>
          <div className='preloader-wrapper active center'>
            <div className='spinner-layer spinner-blue-only'>
              <div className='circle-clipper left'>
                <div className='circle' />
              </div><div className='gap-patch'>
                <div className='circle' />
              </div><div className='circle-clipper right'>
                <div className='circle' />
              </div>
            </div>
          </div>
        </div>
      </div>
    })
  }

  render() {
    const { questionnaire, readOnly } = this.props

    return (
      <Dropdown className='title-options options questionnaire-menu' dataBelowOrigin={false} label={<i className='material-icons'>more_vert</i>}>
        <DropdownItem className='dots'>
          <i className='material-icons'>more_vert</i>
        </DropdownItem>
        <DropdownItem>
          <a href='#' onClick={e => this.exportZip(e)}>
            <i className='material-icons'>file_download</i>
            <span>Export questionnaire</span>
          </a>
        </DropdownItem>
        { !readOnly
          ? <DropdownItem>
            <ConfirmationModal modalId='importModal' ref='importModal' header='Importing questionnaire' initOptions={{dismissible: false}} />
            <input id='questionnaire_import_zip' type='file' accept='.zip' style={{display: 'none'}} onChange={e => this.importZip(e)} />
            <a href='#' onClick={e => this.openImportZipDialog(e)}>
              <i className='material-icons'>file_upload</i>
              <span>Import questionnaire</span>
            </a>
          </DropdownItem>
          : ''}
        { !readOnly
          ? <DropdownItem>
            <a href='#' onClick={e => this.downloadCsv(e)} download={`${questionnaire.name}.csv`}>
              <i className='material-icons'>file_download</i>
              <span>Download contents as CSV</span>
            </a>
          </DropdownItem>
          : ''}
        { !readOnly
          ? <DropdownItem>
            <input id='questionnaire_file_upload' type='file' accept='.csv' style={{display: 'none'}} onChange={e => this.uploadCsv(e)} />
            <a href='#' onClick={e => this.openUploadCsvDialog(e)}>
              <i className='material-icons'>file_upload</i>
              <span>Upload contents as CSV</span>
            </a>
          </DropdownItem>
          : ''}
      </Dropdown>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  readOnly: state.project && state.project.data ? state.project.data.readOnly : true
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch),
  uiActions: bindActionCreators(uiActions, dispatch)
})

export default withQuestionnaire(withRouter(connect(mapStateToProps, mapDispatchToProps)(QuestionnaireMenu)))
