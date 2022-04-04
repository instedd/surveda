import React, { PropTypes, Component } from "react"
import { bindActionCreators } from "redux"
import { connect } from "react-redux"
import { Preloader } from "react-materialize"
import { ConfirmationModal, Card } from "../ui"
import * as actions from "../../actions/respondentGroups"
import uniq from "lodash/uniq"
import flatten from "lodash/flatten"
import { RespondentsList } from "./RespondentsList"
import { RespondentsDropzone } from "./RespondentsDropzone"
import { RespondentsContainer } from "./RespondentsContainer"
import { PhoneNumberRow } from "./PhoneNumberRow"
import { translate } from "react-i18next"

class SurveyWizardRespondentsStep extends Component {
  static propTypes = {
    t: PropTypes.func,
    survey: PropTypes.object,
    respondentGroups: PropTypes.object.isRequired,
    respondentGroupsUploading: PropTypes.bool,
    respondentGroupsUploadingExisting: PropTypes.object,
    invalidRespondents: PropTypes.object,
    invalidGroup: PropTypes.bool,
    channels: PropTypes.object,
    actions: PropTypes.object.isRequired,
    readOnly: PropTypes.bool.isRequired,
    surveyStarted: PropTypes.bool.isRequired,
  }

  handleSubmit(files) {
    const { survey, actions } = this.props
    if (files.length > 0) actions.uploadRespondentGroup(survey.projectId, survey.id, files)
  }

  addMoreRespondents(groupId, file) {
    const { survey, actions } = this.props
    actions.addMoreRespondentsToGroup(survey.projectId, survey.id, groupId, file)
  }

  replaceRespondents(groupId, file) {
    const { survey, actions } = this.props
    actions.replaceRespondents(survey.projectId, survey.id, groupId, file)
  }

  clearInvalids(e) {
    e.preventDefault()

    this.props.actions.clearInvalids()
  }

  invalidEntriesText(invalidEntries, invalidEntryType) {
    const { t } = this.props
    const filteredInvalidEntries = invalidEntries.filter(
      (invalidEntry) => invalidEntry.type == invalidEntryType
    )

    if (filteredInvalidEntries.length == 0) return null

    const lineNumbers = filteredInvalidEntries.slice(0, 3).map((entry) => entry.line_number)
    const entryType = {
      "invalid-phone-number": "phone number",
      "invalid-respondent-id": "respondent id",
    }[invalidEntryType]
    const extraLines = filteredInvalidEntries.length - lineNumbers.length
    const lineNumbersText = lineNumbers.join(", ")

    return extraLines > 0
      ? t("An invalid {{entryType}} was found at line {{lineNumbers}} and {{count}} more.", {
          lineNumbers: lineNumbersText,
          entryType: entryType,
          count: String(extraLines),
        })
      : t("An invalid {{entryType}} was found at line {{lineNumbers}}.", {
          lineNumbers: lineNumbersText,
          entryType: entryType,
        })
  }

  invalidRespondentsContent(data) {
    if (!data) return null

    let { surveyStarted, t } = this.props
    if (surveyStarted) return

    let content = null

    if (data.invalidEntries.length == 0) {
      content = (
        <div className="card-content card-error">
          <div>
            <b>{t("The file you uploaded does not contain any phone number or respondent id")}</b>
          </div>
          <div>{t("Please upload antother file.")}</div>
        </div>
      )
    } else {
      const { invalidEntries } = data
      const invalidPhoneNumbersText = this.invalidEntriesText(
        invalidEntries,
        "invalid-phone-number"
      )
      const invalidRespondentIdsText = this.invalidEntriesText(
        invalidEntries,
        "invalid-respondent-id"
      )

      content = (
        <div className="card-content card-error">
          <div>
            <b>
              {t("Errors found at '{{filename}}', file was not imported", {
                filename: data.filename,
              })}
            </b>
          </div>
          {invalidPhoneNumbersText ? <div>{invalidPhoneNumbersText}</div> : null}
          {invalidRespondentIdsText ? <div>{invalidRespondentIdsText}</div> : null}
          <div>{t("Please fix those errors and upload again.")}</div>
        </div>
      )
    }

    return (
      <Card>
        <div className="card-content card-error">{content}</div>
        <div className="card-action right-align">
          <a className="blue-text" href="#" onClick={(e) => this.clearInvalids(e)}>
            {t("Understood")}
          </a>
        </div>
      </Card>
    )
  }

  channelChange(e, group, mode, allChannels) {
    e.preventDefault()

    let currentChannels = group.channels || []
    currentChannels = currentChannels.filter((channel) => channel.mode != mode)
    if (e.target.value != "") {
      currentChannels.push({
        mode: mode,
        id: parseInt(e.target.value),
      })
    }

    const { actions, survey } = this.props
    actions.selectChannels(survey.projectId, survey.id, group.id, currentChannels)
  }

  openAddOrReplaceModal(group, files) {
    if (files.length < 1) return
    const file = files[0]

    const { survey, t } = this.props

    // If the survey is running, the only option is to add more respondents
    if (survey.state == "running") {
      this.addMoreRespondents(group.id, file)
      return
    }

    const addOrReplaceModal = this.refs.addOrReplaceModal
    addOrReplaceModal.open({
      modalText: (
        <div>
          <p>
            {t("Do you want to add more respondents to this group or completely replace them?")}
          </p>
        </div>
      ),
      confirmationText: t("Add"),
      noText: t("Replace"),
      onConfirm: (e) => {
        this.addMoreRespondents(group.id, file)
        addOrReplaceModal.close()
      },
      onNo: (e) => {
        this.replaceRespondents(group.id, file)
        addOrReplaceModal.close()
      },
      showCancel: true,
    })
  }

  openRemoveRespondentModal(e, ref, groupId) {
    const { survey, actions, t } = this.props
    const modal: ConfirmationModal = ref

    e.preventDefault()

    modal.open({
      modalText: t(
        "Are you sure you want to delete the respondents list? If you confirm, we won't be able to recover it. You will have to upload a new one."
      ),
      onConfirm: () => {
        actions.removeRespondentGroup(survey.projectId, survey.id, groupId)
      },
    })
  }

  renderGroup(group, channels, allModes, readOnly, surveyStarted, uploading) {
    let addMoreRespondents = null

    const { survey, t } = this.props

    if (!readOnly) {
      const addMoreInputId = `addMoreRespondents${group.id}`

      const addMoreClck = (e) => {
        e.preventDefault()
        if (survey.locked) return
        $(`#${addMoreInputId}`).click()
      }

      const addMore = (e) => {
        e.preventDefault()

        const files = e.target.files
        if (files.length < 1) return

        const file = files[0]
        this.addMoreRespondents(group.id, file)
      }

      if (survey.state !== "terminated") {
        if (uploading) {
          addMoreRespondents = <Preloader size="small" className="tiny" />
        } else {
          const addMoreClassName = survey.locked ? "grey-text" : "null"
          addMoreRespondents = [
            <input
              key="x"
              id={addMoreInputId}
              type="file"
              accept=".csv"
              style={{ display: "none" }}
              onChange={(e) => addMore(e)}
            />,
            <a key="y" href="#" onClick={addMoreClck} className={`blue-text ${addMoreClassName}`}>
              {t("Add more respondents")}
            </a>,
          ]
        }
      }
    }

    const removeRespondentsLink = (groupId) => {
      if (!surveyStarted && !uploading) {
        return (
          <a
            href="#"
            className="modal-trigger"
            style={{ marginRight: "0" }}
            onClick={(e) => this.openRemoveRespondentModal(e, this.refs.removeRespondents, groupId)}
          >
            {t("Remove respondents")}
          </a>
        )
      }
    }

    return (
      <RespondentsList
        key={group.id}
        survey={survey}
        group={group}
        add={addMoreRespondents}
        remove={removeRespondentsLink(group.id)}
        modes={allModes}
        channels={channels}
        readOnly={readOnly}
        surveyStarted={surveyStarted}
        onChannelChange={(e, type, allChannels) => this.channelChange(e, group, type, allChannels)}
        onDrop={(files) => this.openAddOrReplaceModal(group, files)}
      >
        {group.sample.map((respondent, index) => (
          <PhoneNumberRow id={respondent} phoneNumber={respondent} key={index} />
        ))}
      </RespondentsList>
    )
  }

  componentWillReceiveProps(props) {
    // Check if any respondent group's respondentsCount changed, to show a toast
    const { t } = this.props
    const groups = this.props.respondentGroups
    if (!groups) return

    for (const id in groups) {
      const group = groups[id]
      const newGroup = props.respondentGroups && props.respondentGroups[id]
      if (!newGroup) continue

      const count = newGroup.respondentsCount - group.respondentsCount
      if (count > 0) {
        window.Materialize.toast(t("{{count}} respondent has been added", { count }), 5000)
      }
    }
  }

  componentDidUpdate() {
    let { actions, invalidGroup, t } = this.props
    if (invalidGroup) {
      const entryType = {
        "invalid-phone-number": "phone number",
        "invalid-respondent-id": "respondent id",
      }[invalidGroup.type]
      t("An invalid {{entryType}} was found at line {{lineNumber}}.", {
        lineNumber: invalidGroup.lineNumber,
        entryType: entryType,
      })
      window.Materialize.toast(
        t("Couldn't upload CSV: an invalid {{entryType}} was found at line {{lineNumber}}.", {
          lineNumber: invalidGroup.lineNumber,
          entryType: entryType,
        }),
        5000
      )
      actions.clearInvalidsRespondentsForGroup()
    }
  }

  render() {
    let {
      survey,
      channels,
      respondentGroups,
      respondentGroupsUploading,
      respondentGroupsUploadingExisting,
      invalidRespondents,
      readOnly,
      surveyStarted,
      t,
    } = this.props
    let invalidRespondentsCard = this.invalidRespondentsContent(invalidRespondents)
    if (!survey || !channels) {
      return <div>{t("Loading...")}</div>
    }

    const mode = survey.mode || []
    const allModes = uniq(flatten(mode))

    let respondentsDropzone = null
    if (!readOnly && !surveyStarted) {
      respondentsDropzone = (
        <RespondentsDropzone
          survey={survey}
          uploading={respondentGroupsUploading}
          onDrop={(file) => this.handleSubmit(file)}
          onDropRejected={() => $("#invalidTypeFile").modal("open")}
        />
      )
    }

    return (
      <RespondentsContainer incentivesEnabled={survey.incentivesEnabled}>
        {Object.keys(respondentGroups).map((groupId) =>
          this.renderGroup(
            respondentGroups[groupId],
            channels,
            allModes,
            readOnly,
            surveyStarted,
            respondentGroupsUploadingExisting[groupId]
          )
        )}

        <ConfirmationModal
          modalId="addOrReplaceGroup"
          ref="addOrReplaceModal"
          header={t("Add or replace respondents")}
        />
        <ConfirmationModal
          modalId="invalidTypeFile"
          modalText={t("The system only accepts CSV files")}
          header={t("Invalid file type")}
          confirmationText={t("Accept")}
          style={{ maxWidth: "600px" }}
        />
        <ConfirmationModal
          modalId={"remove-respondents"}
          ref={"removeRespondents"}
          confirmationText={t("Delete the respondents list")}
          header={t("Please confirm that you want to delete the respondents list")}
          showCancel
        />
        {invalidRespondentsCard || respondentsDropzone}
      </RespondentsContainer>
    )
  }
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch),
})

export default translate()(connect(null, mapDispatchToProps)(SurveyWizardRespondentsStep))
