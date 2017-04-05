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
import QuestionnaireMsg from './QuestionnaireMsg'
import csvString from 'csv-string'
import { ConfirmationModal } from '../ui'
import * as language from '../../language'
import * as routes from '../../routes'
import * as api from '../../api'

type State = {
  addingStep: boolean,
  currentStep: ?Step,
  currentStepIsNew: boolean,
  isNew: boolean
};

class QuestionnaireEditor extends Component {
  state: State

  constructor(props) {
    super(props)
    const initialState = props.location.state
    const isNew = initialState && initialState.isNew
    if (isNew) {
      this.state = this.internalState(null, false, false, true)
    } else {
      this.state = this.internalState(null)
    }
  }

  selectStep(stepId) {
    this.setState(this.internalState(stepId))
  }

  deselectStep() {
    this.setState(this.internalState(null))
  }

  toggleMode(event, mode) {
    this.props.questionnaireActions.toggleMode(mode)
  }

  questionnaireAddStep(e) {
    e.preventDefault()
    this.setState({
      ...this.state,
      addingStep: true
    }, () => {
      // Add the step then automatically expand it
      this.props.questionnaireActions.addStep()
    })
  }

  onOnboardingDismiss() {
    this.props.userSettingsActions.hideOnboarding()
  }

  deleteStep() {
    const currentStepId = this.state.currentStep

    this.setState({
      currentStep: null,
      addingStep: false
    }, () => {
      this.props.questionnaireActions.deleteStep(currentStepId)
    })
  }

  internalState(currentStep, addingStep = false, currentStepIsNew = false, isNew = false) {
    return {
      currentStep,
      addingStep,
      currentStepIsNew,
      isNew
    }
  }

  componentWillReceiveProps(newProps) {
    // This feels a bit hacky, but it let's us expand the step we just created.
    // I couldn't find a better way. Ideally this should be a sort of "callback"
    // to the addStep method, without involving additional component state handling
    // or explicit management via Redux reducers.
    const questionnaireData = newProps.questionnaire

    if (this.state.addingStep && questionnaireData && questionnaireData.steps != null && questionnaireData.steps.length > 0) {
      const newStep = questionnaireData.steps[questionnaireData.steps.length - 1]
      if (newStep != null) {
        this.setState(this.internalState(newStep.id, false, true))
      }
    }
    // A questionnaireData.steps.length > 0 check is added because it's possible
    // having a new questionnaire with 0 steps (deleting the first step and refreshing
    // the page
    if (questionnaireData && questionnaireData.steps && questionnaireData.steps.length > 0 && this.state.isNew) {
      this.selectStep(questionnaireData.steps[0].id)
    }
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
      this.setState({
        ...this.state,
        currentStep: null
      }, () => {
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
    if (questionnaire.languages.length == 2 && questionnaire.steps[0].id == this.state.currentStep) {
      this.setState({
        ...this.state,
        currentStep: null
      })
    }

    this.props.questionnaireActions.removeLanguage(lang)
  }

  render() {
    const { questionnaire, project, readOnly, userSettings } = this.props

    let csvButtons = null

    if (questionnaire == null || project == null || userSettings.settings == null) {
      return <div>Loading...</div>
    }

    const settings = userSettings.settings
    const skipOnboarding = settings.onboarding && settings.onboarding.questionnaire

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
    const mobileWeb = questionnaire.modes.indexOf('mobileWeb') != -1

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
          <div className='row'>
            <div className='col s12'>
              <i className='material-icons v-middle left'>sms</i>
              <span className='mode-label'>SMS</span>
              <div className='switch right'>
                <label>
                  <input type='checkbox' defaultChecked={sms} onClick={e => this.toggleMode(e, 'sms')} disabled={readOnly} />
                  <span className='lever' />
                </label>
              </div>
            </div>
          </div>
          <div className='row'>
            <div className='col s12'>
              <i className='material-icons v-middle left'>phone</i>
              <span className='mode-label'>Phone call</span>
              <div className='switch right'>
                <label>
                  <input type='checkbox' defaultChecked={ivr} onClick={e => this.toggleMode(e, 'ivr')} disabled={readOnly} />
                  <span className='lever' />
                </label>
              </div>
            </div>
          </div>
          <div className='row'>
            <div className='col s12'>
              <i className='material-icons v-middle left'>phonelink</i>
              <span className='mode-label'>Mobile web</span>
              <div className='switch right'>
                <label>
                  <input type='checkbox' defaultChecked={mobileWeb} onClick={e => this.toggleMode(e, 'mobileWeb')} disabled={readOnly} />
                  <span className='lever' />
                </label>
              </div>
            </div>
          </div>
        </div>
        {skipOnboarding
        ? <div className='col s12 m8 offset-m1'>
          <QuestionnaireSteps
            steps={questionnaire.steps}
            current={this.state.currentStep}
            currentStepIsNew={this.state.currentStepIsNew}
            onSelectStep={stepId => this.selectStep(stepId)}
            onDeselectStep={() => this.deselectStep()}
            onDeleteStep={() => this.deleteStep()}
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
            <QuestionnaireMsg title='Quota completed' messageKey='quotaCompletedMsg' readOnly={readOnly} icon='pie_chart' />
          </div>
          <div className='row'>
            <QuestionnaireMsg title='Error' messageKey='errorMsg' readOnly={readOnly} icon='warning' />
          </div>
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
  location: PropTypes.object
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  project: state.project.data,
  userSettings: state.userSettings,
  readOnly: state.project && state.project.data ? state.project.data.readOnly : true,
  questionnaireId: ownProps.params.questionnaireId,
  questionnaire: state.questionnaire.data
})

const mapDispatchToProps = (dispatch) => ({
  projectActions: bindActionCreators(projectActions, dispatch),
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch),
  userSettingsActions: bindActionCreators(userSettingsActions, dispatch)
})

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(QuestionnaireEditor))
