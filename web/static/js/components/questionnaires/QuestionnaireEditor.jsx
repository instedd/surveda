// @flow
import React, { Component, PropTypes } from "react"
import { bindActionCreators } from "redux"
import { withRouter } from "react-router"
import { connect } from "react-redux"
import * as uiActions from "../../actions/ui"
import * as projectActions from "../../actions/project"
import * as questionnaireActions from "../../actions/questionnaire"
import * as userSettingsActions from "../../actions/userSettings"
import QuestionnaireOnboarding from "./QuestionnaireOnboarding"
import QuestionnaireSteps from "./QuestionnaireSteps"
import QuestionnaireImport from "./QuestionnaireImport"
import QuestionnaireImportError from "./QuestionnaireImportError"
import PartialRelevantSettings from "./PartialRelevantSettings"
import LanguagesList from "./LanguagesList"
import SmsSettings from "./SmsSettings"
import PhoneCallSettings from "./PhoneCallSettings"
import WebSettings from "./WebSettings"
import TestQuestionnaireModal from "./TestQuestionnaireModal"
import { Dropdown, DropdownItem, PositionFixer, Tooltip } from "../ui"
import { hasErrorsInModeWithLanguage } from "../../questionnaireErrors"
import classNames from "classnames/bind"
import { translate } from "react-i18next"
import { countRelevantSteps, isQuestionnaireReadOnly } from "../../reducers/questionnaire"
import { isProjectReadOnly } from "../../reducers/project"

type State = {
  isNew: boolean,
}

class QuestionnaireEditor extends Component<any, State> {
  preventSecondImportZipDialog: boolean
  setActiveMode: Function
  addMode: Function
  removeMode: Function
  deleteStep: Function
  deleteQuotaCompletedStep: Function
  selectStep: Function
  deselectStep: Function
  selectQuotaCompletedStep: Function
  deselectQuotaCompletedStep: Function

  constructor(props) {
    super(props)
    this.preventSecondImportZipDialog = false
    this.setActiveMode = this.setActiveMode.bind(this)
    this.addMode = this.addMode.bind(this)
    this.removeMode = this.removeMode.bind(this)
    const initialState = props.location.state
    const isNew = initialState && initialState.isNew
    this.state = { isNew }
    this.deleteStep = this.deleteStep.bind(this)
    this.deleteQuotaCompletedStep = this.deleteQuotaCompletedStep.bind(this)
    this.deleteStep = this.deleteStep.bind(this)
    this.selectStep = this.selectStep.bind(this)
    this.deselectStep = this.deselectStep.bind(this)
    this.selectQuotaCompletedStep = this.selectQuotaCompletedStep.bind(this)
    this.deselectQuotaCompletedStep = this.deselectQuotaCompletedStep.bind(this)
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

  changePartialRelevantEnabled(enabled) {
    this.props.questionnaireActions.changePartialRelevantEnabled(enabled)
  }

  questionnaireAddStep(e) {
    e.preventDefault()

    // Add the step then automatically expand it
    this.props.questionnaireActions.addStepWithCallback().then((step) => {
      this.props.uiActions.selectStep(step.id, true)
    })
  }

  questionnaireAddSection(e) {
    e.preventDefault()

    this.props.questionnaireActions.addSectionWithCallback().then((step) => {
      this.props.uiActions.deselectStep()
    })
  }

  questionnaireAddQuotaCompletedStep(e) {
    e.preventDefault()

    // Add the step then automatically expand it
    this.props.questionnaireActions.addQuotaCompletedStep().then((step) => {
      this.props.uiActions.selectQuotaCompletedStep(step.id, true)
    })
  }

  onOnboardingDismiss() {
    this.props.userSettingsActions.hideOnboarding()
  }

  deleteStep() {
    const currentStepId = this.props.selectedSteps.currentStepId
    this.props.questionnaireActions.deleteStep(currentStepId)
    this.props.uiActions.deselectStep()
  }

  deleteQuotaCompletedStep() {
    const currentStepId = this.props.selectedQuotaCompletedSteps.currentStepId
    this.props.questionnaireActions.deleteStep(currentStepId)
    this.props.uiActions.deselectQuotaCompletedStep()
  }

  selectStep(stepId) {
    this.props.uiActions.selectStep(stepId, this.state.isNew)
  }

  deselectStep() {
    this.props.uiActions.deselectStep()
  }

  selectQuotaCompletedStep(stepId) {
    this.props.uiActions.selectQuotaCompletedStep(stepId, this.state.isNew)
  }

  deselectQuotaCompletedStep() {
    this.props.uiActions.deselectQuotaCompletedStep()
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
    if (
      questionnaire &&
      questionnaire.steps &&
      questionnaire.steps.length > 0 &&
      this.state.isNew
    ) {
      this.props.uiActions.selectStep(questionnaire.steps[0].id, true)
    }

    // Don't consider the questionnaire as new anymore, so the first step
    // is not expanded again
    this.setState({
      isNew: false,
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

  removeLanguage(lang) {
    const { questionnaire, selectedSteps } = this.props

    // If only one language will be left, and the language select step
    // is selected, make sure to unselect it first
    if (
      questionnaire.languages.length == 2 &&
      questionnaire.steps[0].id == selectedSteps.currentStepId
    ) {
      this.props.uiActions.deselectStep()
    }

    this.props.questionnaireActions.removeLanguage(lang)
  }

  modeComponent(mode, label, icon, enabled, readOnly) {
    if (!enabled) return null

    const { questionnaire, errors } = this.props

    const isActive = questionnaire.activeMode == mode
    const hasErrors = hasErrorsInModeWithLanguage(errors, mode, questionnaire.activeLanguage)

    if (isActive) {
      icon = "done"
    }

    let removeModeControl = null
    if (!isActive) {
      removeModeControl = !readOnly ? (
        <span className="remove-mode" onClick={(e) => this.removeMode(e, mode)}>
          <i className="material-icons">highlight_off</i>
        </span>
      ) : (
        <span className="remove-mode">
          <i className="material-icons">{icon}</i>
        </span>
      )
    }

    return (
      <li
        key={mode}
        onClick={(e) => this.setActiveMode(e, mode)}
        className={classNames({
          "active-mode": isActive,
          "tooltip-error": hasErrors,
        })}
      >
        <i className="material-icons v-middle left icon">{icon}</i>
        {removeModeControl}
        <span className="mode-name">{label}</span>
      </li>
    )
  }

  addModeSubcomponent(mode, label, icon, enabled) {
    if (!enabled) return null

    return (
      <DropdownItem>
        <a onClick={(e) => this.addMode(e, mode)}>
          <i className="material-icons">{icon}</i>
          {label}
        </a>
      </DropdownItem>
    )
  }

  addModeComponent(sms, ivr, mobileweb) {
    if (sms && ivr && mobileweb) return null

    const { t } = this.props

    const label = (
      <span>
        <i className="material-icons v-middle left">add</i>
        <span className="mode-label">{t("Add")}</span>
      </span>
    )

    return (
      <div className="row add-mode">
        <div className="col s12">
          <Dropdown label={label} dataBelowOrigin={false}>
            {this.addModeSubcomponent("sms", t("SMS"), "sms", !sms)}
            {this.addModeSubcomponent("ivr", t("Phone call"), "phone", !ivr)}
            {this.addModeSubcomponent("mobileweb", t("Mobile web"), "phonelink", !mobileweb)}
          </Dropdown>
        </div>
      </div>
    )
  }

  addStepComponent() {
    const { readOnly, questionnaireHasSections, t } = this.props

    let addStep = questionnaireHasSections ? null : (
      <a
        href="#!"
        className="btn-flat blue-text no-padd"
        onClick={(e) => this.questionnaireAddStep(e)}
      >
        {t("Add Step")}
      </a>
    )

    return readOnly ? null : (
      <div className="row">
        <div className="col s12">
          <a
            href="#!"
            className="btn-flat blue-text no-hover"
            onClick={(e) => this.questionnaireAddSection(e)}
          >
            {t("Add Section")}
          </a>
          {addStep}
        </div>
      </div>
    )
  }

  openTestQuestionnaireModal(e) {
    e.preventDefault()

    $("#test-questionnaire-modal").modal("open")
  }

  render() {
    const {
      questionnaire,
      questionnaireHasSections,
      errors,
      project,
      readOnly,
      userSettings,
      errorsByPath,
      selectedSteps,
      selectedQuotaCompletedSteps,
      uploadId,
      uploadError,
      uploadProgress,
      userLevel,
      t,
    } = this.props

    if (questionnaire == null || project == null || userSettings.settings == null) {
      return <div>Loading...</div>
    }

    if (uploadError) {
      return <QuestionnaireImportError description={uploadError} />
    } else if (uploadId) {
      return <QuestionnaireImport percentage={uploadProgress} />
    }

    const settings = userSettings.settings
    // emptyQuestionnaire is to show onboarding to fresh users with write level in new or empty questionnaires. As questionnaires are created with an empty step, all this conditions are necessary to check if it is actually empty
    const emptyChoices =
      questionnaire.steps.length == 0 ||
      (questionnaire.steps[0].choices && questionnaire.steps[0].choices.length == 0)
    const emptyQuestionnaire =
      !questionnaireHasSections &&
      !questionnaire.name &&
      (questionnaire.steps.length == 0 || (questionnaire.steps[0].title == "" && emptyChoices))
    const skipOnboarding =
      !emptyQuestionnaire ||
      (settings.onboarding && settings.onboarding.questionnaire) ||
      userLevel == "reader"
    const hasQuotaCompletedSteps = !!questionnaire.quotaCompletedSteps
    const partialRelevantEnabled =
      questionnaire.partialRelevantConfig && questionnaire.partialRelevantConfig.enabled
    const partialRelevantMinRelevantSteps =
      partialRelevantEnabled && questionnaire.partialRelevantConfig.minRelevantSteps
    const partialRelevantIgnoredValues =
      partialRelevantEnabled && questionnaire.partialRelevantConfig.ignoredValues
    const relevantStepsQuantity = partialRelevantEnabled && countRelevantSteps(questionnaire.steps)

    let testControls = null
    if (!readOnly && errors.length == 0) {
      testControls = (
        <div>
          <Tooltip text="Test Sandbox">
            <a
              key="one"
              className="btn-floating btn-large waves-effect waves-light green right mtop"
              href="#"
              onClick={(e) => this.openTestQuestionnaireModal(e)}
            >
              <i className="material-icons">videogame_asset</i>
            </a>
          </Tooltip>
          <TestQuestionnaireModal key="two" modalId="test-questionnaire-modal" />
        </div>
      )
    }

    const sms = questionnaire.modes.indexOf("sms") != -1
    const ivr = questionnaire.modes.indexOf("ivr") != -1
    const mobileweb = questionnaire.modes.indexOf("mobileweb") != -1

    const renderSwitchInTable = ({
      checked,
      onChange,
      disabled,
      text,
      classes,
    }: renderSwitchProps) => {
      return (
        <div className="row">
          <div className="col s12">
            <div className={classNames("switch", classes)}>
              <label>
                <input type="checkbox" checked={checked} onChange={onChange} disabled={disabled} />
                <span className="lever" />
              </label>
              {text}
            </div>
          </div>
        </div>
      )
    }

    return (
      <div>
        {testControls}
        <div className="row">
          <div className="col s12 m3 questionnaire-modes">
            <PositionFixer>
              <LanguagesList
                onRemoveLanguage={(lang) => this.removeLanguage(lang)}
                readOnly={readOnly}
              />
              <div className="row">
                <div className="col s12">
                  <p className="grey-text">{t("Modes")}</p>
                  <ul className="modes-list">
                    {this.modeComponent("sms", t("SMS"), "sms", sms, readOnly)}
                    {this.modeComponent("ivr", t("Phone call"), "phone", ivr, readOnly)}
                    {this.modeComponent(
                      "mobileweb",
                      t("Mobile web"),
                      "phonelink",
                      mobileweb,
                      readOnly
                    )}
                  </ul>
                  {!readOnly ? this.addModeComponent(sms, ivr, mobileweb) : null}
                </div>
              </div>
            </PositionFixer>
          </div>
          {skipOnboarding ? (
            <div className="col s12 m8 offset-m1">
              <QuestionnaireSteps
                ref="stepsComponent"
                steps={questionnaire.steps}
                errorPath="steps"
                errorsByPath={errorsByPath}
                onDeleteStep={this.deleteStep}
                onSelectStep={this.selectStep}
                onDeselectStep={this.deselectStep}
                readOnly={readOnly}
                selectedSteps={selectedSteps}
              />
              {this.addStepComponent()}
              {renderSwitchInTable({
                checked: hasQuotaCompletedSteps,
                onChange: (e) => this.toggleQuotaCompletedSteps(e),
                disabled: readOnly,
                text: t("Quota completed steps"),
              })}
              {hasQuotaCompletedSteps ? (
                <QuestionnaireSteps
                  ref="quotaCompletedStepsComponent"
                  quotaCompletedSteps
                  steps={questionnaire.quotaCompletedSteps}
                  errorPath="quotaCompletedSteps"
                  errorsByPath={errorsByPath}
                  onDeleteStep={this.deleteQuotaCompletedStep}
                  onSelectStep={this.selectQuotaCompletedStep}
                  onDeselectStep={this.deselectQuotaCompletedStep}
                  readOnly={readOnly}
                  selectedSteps={selectedQuotaCompletedSteps}
                />
              ) : null}
              {!readOnly && hasQuotaCompletedSteps ? (
                <div className="row">
                  <div className="col s12">
                    <a
                      href="#!"
                      className="btn-flat blue-text no-padd"
                      onClick={(e) => this.questionnaireAddQuotaCompletedStep(e)}
                    >
                      {t("Add Quota Completed Step")}
                    </a>
                  </div>
                </div>
              ) : null}
              {renderSwitchInTable({
                checked: partialRelevantEnabled,
                onChange: () => this.changePartialRelevantEnabled(!partialRelevantEnabled),
                classes: "partial-relevant",
                disabled: readOnly,
                text: t("Partial relevant"),
              })}
              {partialRelevantEnabled ? (
                <PartialRelevantSettings
                  readOnly={readOnly}
                  minRelevantSteps={partialRelevantMinRelevantSteps}
                  changeMinRelevantSteps={(changed) =>
                    this.props.questionnaireActions.changePartialRelevantMinRelevantSteps(changed)
                  }
                  ignoredValues={partialRelevantIgnoredValues}
                  changeIgnoredValues={(changed) =>
                    this.props.questionnaireActions.changePartialRelevantIgnoredValues(changed)
                  }
                  errorsByPath={errorsByPath}
                  relevantStepsQuantity={relevantStepsQuantity}
                />
              ) : null}

              {questionnaire.activeMode == "sms" ? <SmsSettings readOnly={readOnly} /> : null}
              {questionnaire.activeMode == "ivr" ? <PhoneCallSettings readOnly={readOnly} /> : null}
              {questionnaire.activeMode == "mobileweb" ? <WebSettings readOnly={readOnly} /> : null}
            </div>
          ) : (
            <QuestionnaireOnboarding onDismiss={() => this.onOnboardingDismiss()} />
          )}
        </div>
      </div>
    )
  }
}

QuestionnaireEditor.propTypes = {
  projectActions: PropTypes.object.isRequired,
  uiActions: PropTypes.object.isRequired,
  questionnaireActions: PropTypes.object.isRequired,
  userSettingsActions: PropTypes.object.isRequired,
  t: PropTypes.func,
  router: PropTypes.object,
  project: PropTypes.object,
  userSettings: PropTypes.object,
  readOnly: PropTypes.bool,
  projectId: PropTypes.any,
  questionnaireId: PropTypes.any,
  questionnaire: PropTypes.object,
  questionnaireHasSections: PropTypes.bool,
  errors: PropTypes.array,
  errorsByPath: PropTypes.object,
  location: PropTypes.object,
  selectedSteps: PropTypes.object,
  selectedQuotaCompletedSteps: PropTypes.object,
  uploadId: PropTypes.string,
  uploadError: PropTypes.oneOfType([PropTypes.array, PropTypes.string]),
  uploadProgress: PropTypes.number,
  userLevel: PropTypes.string,
}

type renderSwitchProps = {
  checked: boolean,
  onChange: Function,
  disabled: boolean,
  text: string,
  classes?: string,
}

const mapStateToProps = (state, ownProps) => {
  const questionnaire = state.questionnaire && state.questionnaire.data
  return {
    projectId: ownProps.params.projectId,
    project: state.project.data,
    userSettings: state.userSettings,
    readOnly: isProjectReadOnly(state) || isQuestionnaireReadOnly(state),
    questionnaireId: ownProps.params.questionnaireId,
    questionnaire,
    questionnaireHasSections: questionnaire
      ? questionnaire.steps.some(function (item) {
          return item.type == "section"
        })
      : false,
    errors: state.questionnaire.errors,
    errorsByPath: state.questionnaire.errorsByPath || {},
    selectedSteps: state.ui.data.questionnaireEditor.steps,
    selectedQuotaCompletedSteps: state.ui.data.questionnaireEditor.quotaCompletedSteps,
    uploadId: state.ui.data.questionnaireEditor.upload.uploadId,
    uploadError: state.ui.data.questionnaireEditor.upload.error,
    uploadProgress: state.ui.data.questionnaireEditor.upload.progress,
    userLevel: state.project.data ? state.project.data.level : "",
  }
}

const mapDispatchToProps = (dispatch) => ({
  projectActions: bindActionCreators(projectActions, dispatch),
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch),
  userSettingsActions: bindActionCreators(userSettingsActions, dispatch),
  uiActions: bindActionCreators(uiActions, dispatch),
})

export default translate()(
  withRouter(connect(mapStateToProps, mapDispatchToProps)(QuestionnaireEditor))
)
