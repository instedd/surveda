import React, { Component, PropTypes } from "react"
import { translate, Trans } from "react-i18next"

import { Link } from "react-router"
import * as routes from "../../routes"
import * as surveyActions from "../../actions/survey"
import * as panelSurveyActions from "../../actions/panelSurvey"
import { fetchRespondentsStats } from "../../actions/respondents"
import { untitledSurveyTitle } from "./SurveyTitle"
import { Card, ConfirmationModal, Dropdown, DropdownItem, Modal, UntitledIfEmpty } from "../ui"
import RespondentsChart from "../respondents/RespondentsChart"
import SurveyStatus from "../surveys/SurveyStatus"
import MoveSurveyForm from "./MoveSurveyForm"
import classNames from "classnames/bind"

import { connect } from "react-redux"

class _SurveyCard extends Component<any> {
  props: {
    t: Function,
    dispatch: Function,
    survey: Survey,
    readOnly: boolean,
  }

  constructor(props) {
    super(props)

    this.state = {
      folderId: props.survey.folderId || "",
    }
  }

  componentDidMount() {
    const { survey, dispatch } = this.props
    if (survey.state != "not_ready") {
      fetchRespondentsStats(survey.projectId, survey.id)(dispatch)
    }
  }

  changeFolder = (folderId) => this.setState({ folderId })

  askMoveSurvey = () => {
    const moveSurveyConfirmationModal: ConfirmationModal = this.refs.moveSurveyConfirmationModal
    const { survey } = this.props
    const modalText = (
      <MoveSurveyForm
        projectId={survey.projectId}
        defaultFolderId={survey.folderId}
        onChangeFolderId={(folderId) => this.changeFolder(folderId)}
      />
    )
    moveSurveyConfirmationModal.open({
      modalText: modalText,
      onConfirm: () => this.confirmMoveSurvey(survey),
    })
  }

  confirmMoveSurvey = (survey: Survey) => {
    const { dispatch } = this.props
    const { folderId } = this.state
    dispatch(surveyActions.changeFolder(survey, folderId))
  }

  askDeleteSurvey = () => {
    const deleteConfirmationModal: ConfirmationModal = this.refs.deleteConfirmationModal
    const { t, survey } = this.props
    deleteConfirmationModal.open({
      modalText: (
        <span>
          <p>
            <Trans>
              Are you sure you want to delete the survey{" "}
              <b>
                <UntitledIfEmpty text={survey.name} emptyText={untitledSurveyTitle(survey, t)} />
              </b>
              ?
            </Trans>
          </p>
          <p>{t("All the respondent information will be lost and cannot be undone.")}</p>
        </span>
      ),
      onConfirm: () => this.confirmDeleteSurvey(survey),
    })
  }

  confirmDeleteSurvey = (survey: Survey) => {
    const { dispatch } = this.props
    dispatch(surveyActions.deleteSurvey(survey))
  }

  deletable() {
    const { survey, readOnly } = this.props
    return !readOnly && survey.isDeletable
  }

  movable() {
    const { survey, readOnly } = this.props
    return !readOnly && survey.isMovable
  }

  actionable() {
    return this.deletable() || this.movable()
  }

  render() {
    const { survey, t, dispatch } = this.props

    let actions = []
    if (this.movable()) actions.push({ name: t("Move to"), func: this.askMoveSurvey })
    if (this.deletable()) actions.push({ name: t("Delete"), func: this.askDeleteSurvey })

    return (
      <div className="col s12 m6 l4">
        <InnerSurveyCard
          survey={survey}
          actions={actions}
          onClickRoute={routes.showOrEditSurvey(survey)}
          t={t}
          dispatch={dispatch}
        />

        <ConfirmationModal
          modalId="survey_index_move_survey"
          ref="moveSurveyConfirmationModal"
          confirmationText={t("Move")}
          header={t("Move survey")}
          showCancel
        />
        <ConfirmationModal
          modalId="survey_index_delete"
          ref="deleteConfirmationModal"
          confirmationText={t("Delete")}
          header={t("Delete survey")}
          showCancel
        />
      </div>
    )
  }
}
class _PanelSurveyCard extends Component<any> {
  props: {
    t: Function,
    dispatch: Function,
    panelSurvey: Survey,
    readOnly: boolean,
  }

  constructor(props) {
    super(props)
    this.state = { folderId: props.panelSurvey.folderId || "" }
  }

  latestWave() {
    const { panelSurvey } = this.props
    return panelSurvey.latestWave
  }

  changeFolder(folderId) {
    this.setState({ folderId })
  }

  askMovePanelSurvey = () => {
    const { panelSurvey } = this.props

    this.refs.moveSurveyConfirmationModal.open({
      modalText: (
        <MoveSurveyForm
          projectId={panelSurvey.projectId}
          defaultFolderId={panelSurvey.folderId}
          onChangeFolderId={(folderId) => this.changeFolder(folderId)}
        />
      ),
      onConfirm: () => this.confirmMovePanelSurvey(panelSurvey),
    })
  }

  confirmMovePanelSurvey = (panelSurvey: PanelSurvey) => {
    const { dispatch } = this.props
    const { folderId } = this.state
    dispatch(panelSurveyActions.changeFolder(panelSurvey, folderId))
  }

  askDeletePanelSurveyWave = () => {
    const { t } = this.props

    const wave = this.latestWave()

    this.refs.deleteSurveyConfirmationModal.open({
      modalText: (
        <span>
          <p>
            <Trans>
              Are you sure you want to delete the last wave{" "}
              <b>
                <UntitledIfEmpty text={wave.name} emptyText={untitledSurveyTitle(wave, t)} />
              </b>
              ?
            </Trans>
          </p>
          <p>{t("All the respondent information will be lost and cannot be undone.")}</p>
        </span>
      ),
      onConfirm: () => this.confirmDeletePanelSurveyWave(wave),
    })
  }

  confirmDeletePanelSurveyWave = (wave: Survey) => {
    const { dispatch, panelSurvey } = this.props
    dispatch(surveyActions.deletePanelSurveyWave(panelSurvey, wave))
  }

  askDeletePanelSurvey = () => {
    const { panelSurvey } = this.props

    this.refs.deletePanelSurveyConfirmationModal.open({
      onConfirm: () => this.confirmDeletePanelSurvey(panelSurvey),
    })
  }

  confirmDeletePanelSurvey = (panelSurvey: PanelSurvey) => {
    const { dispatch } = this.props
    dispatch(panelSurveyActions.deletePanelSurvey(panelSurvey))
  }

  // The option Delete on the PanelSurveyCard means:
  // delete the last wave in the PanelSurvey
  deletable() {
    const { readOnly } = this.props
    const survey = this.latestWave()

    return !readOnly && survey.isDeletable
  }

  movable() {
    const { readOnly } = this.props
    return !readOnly
  }

  actionable() {
    return this.deletable() || this.movable()
  }

  render() {
    const { panelSurvey, t, dispatch } = this.props
    const survey = this.latestWave()

    let actions = []
    if (this.movable()) actions.push({ name: t("Move to"), func: this.askMovePanelSurvey })
    if (this.deletable())
      actions.push({
        name: t("Delete wave"),
        func: this.askDeletePanelSurveyWave,
      })
    actions.push({
      name: t("Delete Panel Survey"),
      func: this.askDeletePanelSurvey,
    })

    return (
      <div className="col s12 m6 l4">
        <div className="panel-survey-card-0">
          <div className="panel-survey-card-1">
            <div className="panel-survey-card-2">
              <InnerSurveyCard
                survey={survey}
                actions={actions}
                onClickRoute={routes.panelSurvey(survey.projectId, panelSurvey.id)}
                t={t}
                dispatch={dispatch}
              />
            </div>
          </div>
        </div>

        <ConfirmationModal
          modalId="survey_index_move_survey"
          ref="moveSurveyConfirmationModal"
          confirmationText={t("Move")}
          header={t("Move survey")}
          showCancel
        />
        <ConfirmationModal
          modalId="survey_index_delete"
          ref="deleteSurveyConfirmationModal"
          confirmationText={t("Delete")}
          header={t("Delete survey")}
          showCancel
        />
        <TwoStepsConfirmationModal
          modalId="panel_survey_index_delete"
          ref="deletePanelSurveyConfirmationModal"
          t={t}
        />
      </div>
    )
  }
}

class InnerSurveyCard extends Component<any> {
  props: {
    survey: Survey,
    actions: Array<Object>,
    onClickRoute: Function,
    t: Function,
    respondentsStats: ?Object,
    dispatch: Function,
  }

  componentDidMount() {
    const { survey, dispatch } = this.props

    if (survey.state != "not_ready") {
      fetchRespondentsStats(survey.projectId, survey.id)(dispatch)
    }
  }

  render() {
    const { survey, respondentsStats, actions, onClickRoute, t } = this.props

    // stats
    let cumulativePercentages = respondentsStats
      ? respondentsStats["cumulativePercentages"] || {}
      : {}
    let completionPercentage = respondentsStats ? respondentsStats["completionPercentage"] || 0 : 0

    return (
      <div className="survey-card">
        <Card>
          <div className="card-content">
            <div className="survey-card-status">
              <Link className="grey-text" to={onClickRoute}>
                {t("{{percentage}}% of target completed", {
                  percentage: String(Math.round(completionPercentage)),
                })}
              </Link>
              <ActionMenu actions={actions} />
            </div>
            <div className="card-chart">
              <RespondentsChart cumulativePercentages={cumulativePercentages} />
            </div>
            <div className="card-status">
              <Link
                className="card-title black-text truncate"
                title={survey.name}
                to={onClickRoute}
              >
                <UntitledIfEmpty text={survey.name} emptyText={untitledSurveyTitle(survey, t)} />
              </Link>
              <Link to={onClickRoute}>
                <div className="grey-text card-description">{survey.description}</div>
                <SurveyStatus survey={survey} short />
              </Link>
            </div>
          </div>
        </Card>
      </div>
    )
  }
}

const ActionMenu = (props) => {
  const { actions } = props

  if (actions.length === 0) return null

  return (
    <Dropdown
      className="options"
      dataBelowOrigin={false}
      label={<i className="material-icons">more_vert</i>}
    >
      <DropdownItem className="dots">
        <i className="material-icons">more_vert</i>
      </DropdownItem>
      {actions.map((action, index) => (
        <DropdownItem key={index}>
          <a onClick={(e) => action.func()}>
            <i className="material-icons">folder</i>
            {action.name}
          </a>
        </DropdownItem>
      ))}
    </Dropdown>
  )
}

ActionMenu.propTypes = {
  actions: PropTypes.array,
}

class TwoStepsConfirmationModal extends Component<Props, State> {
  static propTypes = {
    modalId: PropTypes.string,
    t: PropTypes.func,
  }

  constructor(props: Props) {
    super(props)
    this.state = { checked: false }
  }

  open(props) {
    if (props) this.setState(props)
    this.refs.modal.open()
  }

  close() {
    this.refs.modal.close()
  }

  toggleChecked() {
    this.setState((state) => ({ checked: !state.checked }))
  }

  onConfirmClick = async (e) => {
    const { onConfirm } = this.state

    e.preventDefault()

    if (!onConfirm) {
      this.refs.modal.close()
      return
    }

    const res = await onConfirm()
    res !== false && this.refs.modal.close()
  }

  render() {
    const { checked } = this.state
    const { modalId, t } = this.props

    return (
      <div style={{ textAlign: "center" }}>
        <Modal card id={modalId} ref="modal">
          <div className="modal-content">
            <div className="card-title header" style={{ marginBottom: "48px" }}>
              <h5>{t("Delete Panel Survey")}</h5>
            </div>
            <div className="card-content">
              <div className="row">
                <div className="col s12">
                  <p className="red-text alert-left-icon">
                    <i className="material-icons">warning</i>
                    {t("Panel Survey deletion cannot be undone")}
                  </p>
                </div>
              </div>
              <div className="row">
                <div className="col s12">
                  <p>{t("You are about to delete all the waves of this panel survey.")}</p>
                  <p>{t(`All the information of all the waves will be lost.`)}</p>
                </div>
              </div>
              <div className="row">
                <div className="col s12">
                  <input
                    id="delete_panel_survey_understood"
                    type="checkbox"
                    checked={checked}
                    onChange={() => this.toggleChecked()}
                    className="filled-in"
                  />
                  <label htmlFor="delete_panel_survey_understood">{t("Understood")}</label>
                </div>
              </div>
            </div>
            <div className="card-action">
              <a
                className={classNames("btn red", { disabled: !checked })}
                onClick={(e) => this.onConfirmClick(e)}
              >
                {t("Delete Panel Survey")}
              </a>
              <a
                className="modal-action modal-close btn-flat grey-text"
                onClick={() => this.close()}
              >
                {t("Cancel")}
              </a>
            </div>
          </div>
        </Modal>
      </div>
    )
  }
}

export const SurveyCard = translate()(connect()(_SurveyCard))
export const PanelSurveyCard = translate()(connect()(_PanelSurveyCard))
