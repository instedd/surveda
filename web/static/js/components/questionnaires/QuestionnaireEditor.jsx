// @flow
import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { withRouter } from 'react-router'
import { connect } from 'react-redux'
import * as projectActions from '../../actions/project'
import * as questionnaireActions from '../../actions/questionnaire'
import * as userSettingsActions from '../../actions/userSettings'
import { csvForTranslation, csvTranslationFilename } from '../../reducers/questionnaire'
import QuestionnaireOnboarding from './QuestionnaireOnboarding'
import QuestionnaireSteps from './QuestionnaireSteps'
import LanguagesList from './LanguagesList'
import SmsSettings from './SmsSettings'
import PhoneCallSettings from './PhoneCallSettings'
import WebSettings from './WebSettings'
import csvString from 'csv-string'
import { ConfirmationModal, Dropdown, DropdownItem } from '../ui'
import { hasErrorsInModeWithLanguage } from '../../questionnaireErrors'
import * as language from '../../language'
import * as routes from '../../routes'
import * as api from '../../api'

type State = {
  isNew: boolean
};

class QuestionnaireEditor extends Component {
  state: State
  preventSecondImportZipDialog: boolean
  setActiveMode: Function
  addMode: Function
  removeMode: Function
  deleteStep: Function

  constructor(props) {
    super(props)
    this.preventSecondImportZipDialog = false
    this.setActiveMode = this.setActiveMode.bind(this)
    this.addMode = this.addMode.bind(this)
    this.removeMode = this.removeMode.bind(this)
    const initialState = props.location.state
    const isNew = initialState && initialState.isNew
    this.state = {isNew}
    this.deleteStep = this.deleteStep.bind(this)
  }

  setActiveMode(e, mode) {
    e.preventDefault()
    e.stopPropagation()
    this.props.questionnaireActions.setActiveMode(mode)
  }

  addMode(e, mode) {
    e.preventDefault()
    e.stopPropagation()
    this.props.questionnaireActions.addMode(mode)
  }

  removeMode(e, mode) {
    e.preventDefault()
    e.stopPropagation()
    this.props.questionnaireActions.removeMode(mode)
  }

  toggleQuotaCompletedSteps(e) {
    this.props.questionnaireActions.toggleQuotaCompletedSteps()
  }

  questionnaireAddStep(e) {
    e.preventDefault()

    // Add the step then automatically expand it
    this.props.questionnaireActions.addStepWithCallback().then(step => {
      this.stepsComponent().selectStep(step.id, true)
    })
  }

  questionnaireAddQuotaCompletedStep(e) {
    e.preventDefault()

    // Add the step then automatically expand it
    this.props.questionnaireActions.addQuotaCompletedStep().then(step => {
      this.quotaCompletedStepsComponent().selectStep(step.id, true)
    })
  }

  onOnboardingDismiss() {
    this.props.userSettingsActions.hideOnboarding()
  }

  deleteStep(stepId) {
    this.props.questionnaireActions.deleteStep(stepId)
  }

  stepsComponent() {
    // Because QuestionnaireSteps is inside a DragDropContext
    return this.refs.stepsComponent.child
  }

  quotaCompletedStepsComponent() {
    // Because QuestionnaireSteps is inside a DragDropContext
    return this.refs.quotaCompletedStepsComponent.child
  }

  componentWillReceiveProps(newProps) {
    const questionnaire = newProps.questionnaire

    // If it's a new questionnaire, expand the first step
    if (questionnaire && questionnaire.steps && questionnaire.steps.length > 0 && this.state.isNew) {
      this.stepsComponent().selectStep(questionnaire.steps[0].id, true)
    }

    // Don't consider the questionnaire as new anymore, so the first step
    // is not expanded again
    this.setState({
      isNew: false
    })
  }

  componentWillMount() {
    const { projectId, questionnaireId } = this.props

    if (projectId && questionnaireId) {
      this.props.projectActions.fetchProject(projectId)
      this.props.questionnaireActions.fetchQuestionnaireIfNeeded(projectId, questionnaireId)
      this.props.userSettingsActions.fetchSettings()
    }
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

    const { projectId, questionnaireId } = this.props
    window.location = routes.exportQuestionnaireZip(projectId, questionnaireId)
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

    const { projectId, questionnaireId } = this.props
    const importModal = this.refs.importModal

    api.importQuestionnaireZip(projectId, questionnaireId, files)
    .then(response => {
      const questionnaire = response.entities.questionnaires[response.result]
      // Make sure to deselect any step before receiving the questionnaire
      this.stepsComponent().deselectStep(() => {
        this.props.questionnaireActions.receive(questionnaire)
        importModal.close()
      })
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

  removeLanguage(lang) {
    const { questionnaire } = this.props

    // If only one language will be left, and the language select step
    // is selected, make sure to unselect it first
    if (questionnaire.languages.length == 2 && questionnaire.steps[0].id == this.stepsComponent().getCurrentStepId()) {
      this.stepsComponent().deselectStep()
    }

    this.props.questionnaireActions.removeLanguage(lang)
  }

  modeComponent(mode, label, icon, enabled) {
    if (!enabled) return null

    const { questionnaire, errors } = this.props

    let spanClassName = 'mode-label'
    if (questionnaire.activeMode == mode) {
      spanClassName += ' active'
      icon = 'done'
    }

    let rowClassName = 'row mode-list'
    if (hasErrorsInModeWithLanguage(errors, mode, questionnaire.activeLanguage)) {
      rowClassName += ' tooltip-error'
    }

    return (
      <div className={rowClassName} onClick={e => this.setActiveMode(e, mode)}>
        <div className='col s12'>
          <i className='material-icons v-middle left delete-mode' onClick={e => this.removeMode(e, mode)}>highlight_off</i>
          <i className='material-icons v-middle left'>{icon}</i>
          <span className={spanClassName}>{label}</span>
        </div>
      </div>
    )
  }

  addModeSubcomponent(mode, label, icon, enabled) {
    if (!enabled) return null

    return (
      <DropdownItem>
        <a onClick={e => this.addMode(e, mode)}><i className='material-icons'>{icon}</i>{label}</a>
      </DropdownItem>
    )
  }

  addModeComponent(sms, ivr, mobileweb) {
    if (sms && ivr && mobileweb) return null

    const label = (
      <span>
        <i className='material-icons v-middle left'>add</i>
        <span className='mode-label'>Add</span>
      </span>
    )

    return (
      <div className='row add-mode'>
        <div className='col s12'>
          <Dropdown label={label} dataBelowOrigin={false}>
            { this.addModeSubcomponent('sms', 'SMS', 'sms', !sms) }
            { this.addModeSubcomponent('ivr', 'Phone call', 'phone', !ivr) }
            { this.addModeSubcomponent('mobileweb', 'Mobile web', 'phonelink', !mobileweb) }
          </Dropdown>
        </div>
      </div>
    )
  }

  render() {
    const { questionnaire, project, readOnly, userSettings, errorsByPath } = this.props

    let csvButtons = null

    if (questionnaire == null || project == null || userSettings.settings == null) {
      return <div>Loading...</div>
    }

    const settings = userSettings.settings
    const skipOnboarding = settings.onboarding && settings.onboarding.questionnaire
    const hasQuotaCompletedSteps = !!questionnaire.quotaCompletedSteps

    if (!readOnly) {
      csvButtons = <div>
        <div className='row'>
          <div className='col s12'>
            <a className='btn-icon-grey' href='#' onClick={e => this.downloadCsv(e)} download={`${questionnaire.name}.csv`}>
              <i className='material-icons'>file_download</i>
              <span>Download contents as CSV</span>
            </a>
          </div>
        </div>
        <div className='row'>
          <div className='col s12'>
            <input id='questionnaire_file_upload' type='file' accept='.csv' style={{display: 'none'}} onChange={e => this.uploadCsv(e)} />
            <a className='btn-icon-grey' href='#' onClick={e => this.openUploadCsvDialog(e)}>
              <i className='material-icons'>file_upload</i>
              <span>Upload contents as CSV</span>
            </a>
          </div>
        </div>
      </div>
    }

    const sms = questionnaire.modes.indexOf('sms') != -1
    const ivr = questionnaire.modes.indexOf('ivr') != -1
    const mobileweb = questionnaire.modes.indexOf('mobileweb') != -1

    return (
      <div className='row'>
        <div className='col s12 m3 questionnaire-modes'>
          <LanguagesList onRemoveLanguage={(lang) => this.removeLanguage(lang)} readOnly={readOnly} />
          {csvButtons}
          <div className='row'>
            <div className='col s12'>
              <a className='btn-icon-grey' href='#' onClick={e => this.exportZip(e)}>
                <i className='material-icons'>file_download</i>
                <span>Export questionnaire</span>
              </a>
            </div>
          </div>
          <div className='row'>
            <div className='col s12'>
              <ConfirmationModal modalId='importModal' ref='importModal' header='Importing questionnaire' initOptions={{dismissible: false}} />
              <input id='questionnaire_import_zip' type='file' accept='.zip' style={{display: 'none'}} onChange={e => this.importZip(e)} />
              <a className='btn-icon-grey' href='#' onClick={e => this.openImportZipDialog(e)}>
                <i className='material-icons'>file_upload</i>
                <span>Import questionnaire</span>
              </a>
            </div>
          </div>
          <div className='row'>
            <div className='col s12'>
              <p className='grey-text'>Modes</p>
            </div>
          </div>
          { this.modeComponent('sms', 'SMS', 'sms', sms) }
          { this.modeComponent('ivr', 'Phone call', 'phone', ivr) }
          { this.modeComponent('mobileweb', 'Mobile web', 'phonelink', mobileweb) }
          { this.addModeComponent(sms, ivr, mobileweb) }
        </div>
        {skipOnboarding
        ? <div className='col s12 m8 offset-m1'>
          <QuestionnaireSteps
            ref='stepsComponent'
            steps={questionnaire.steps}
            errorPath='steps'
            errorsByPath={errorsByPath}
            onDeleteStep={this.deleteStep}
            readOnly={readOnly}
            />
          {readOnly ? null
          : <div className='row'>
            <div className='col s12'>
              <a href='#!' className='btn-flat blue-text no-padd' onClick={e => this.questionnaireAddStep(e)}>Add Step</a>
            </div>
          </div>
          }
          <div className='row'>
            <div className='col s12'>
              <div className='switch'>
                <label>
                  <input type='checkbox' checked={hasQuotaCompletedSteps} onChange={e => this.toggleQuotaCompletedSteps(e)} disabled={readOnly} />
                  <span className='lever' />
                </label>
                Quota completed steps
              </div>
            </div>
          </div>
          {hasQuotaCompletedSteps
          ? <QuestionnaireSteps
            ref='quotaCompletedStepsComponent'
            quotaCompletedSteps
            steps={questionnaire.quotaCompletedSteps}
            errorPath='quotaCompletedSteps'
            errorsByPath={errorsByPath}
            onDeleteStep={this.deleteStep}
            readOnly={readOnly}
            />
          : null}
          {!readOnly && hasQuotaCompletedSteps
          ? <div className='row'>
            <div className='col s12'>
              <a href='#!' className='btn-flat blue-text no-padd' onClick={e => this.questionnaireAddQuotaCompletedStep(e)}>Add Quota Completed Step</a>
            </div>
          </div>
          : null
          }
          { questionnaire.activeMode == 'sms'
          ? <SmsSettings readOnly={readOnly} />
          : null }
          { questionnaire.activeMode == 'ivr'
          ? <PhoneCallSettings readOnly={readOnly} />
          : null }
          { questionnaire.activeMode == 'mobileweb'
          ? <WebSettings readOnly={readOnly} />
          : null }
        </div>
        : <QuestionnaireOnboarding onDismiss={() => this.onOnboardingDismiss()} />
        }
      </div>
    )
  }
}

QuestionnaireEditor.propTypes = {
  projectActions: PropTypes.object.isRequired,
  questionnaireActions: PropTypes.object.isRequired,
  userSettingsActions: PropTypes.object.isRequired,
  router: PropTypes.object,
  project: PropTypes.object,
  userSettings: PropTypes.object,
  readOnly: PropTypes.bool,
  projectId: PropTypes.any,
  questionnaireId: PropTypes.any,
  questionnaire: PropTypes.object,
  errors: PropTypes.array,
  errorsByPath: PropTypes.object,
  location: PropTypes.object
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  project: state.project.data,
  userSettings: state.userSettings,
  readOnly: state.project && state.project.data ? state.project.data.readOnly : true,
  questionnaireId: ownProps.params.questionnaireId,
  questionnaire: state.questionnaire.data,
  errors: state.questionnaire.errors,
  errorsByPath: state.questionnaire.errorsByPath || {}
})

const mapDispatchToProps = (dispatch) => ({
  projectActions: bindActionCreators(projectActions, dispatch),
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch),
  userSettingsActions: bindActionCreators(userSettingsActions, dispatch)
})

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(QuestionnaireEditor))
