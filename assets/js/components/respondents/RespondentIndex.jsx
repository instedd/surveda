// @flow
import React, { Component } from "react"
import { bindActionCreators } from "redux"
import { connect } from "react-redux"
// $FlowFixMe - there's no react-timeago definitions in flow-typed
import TimeAgo from "react-timeago"
import * as api from "../../api"
import * as actions from "../../actions/respondents"
import { fieldUniqueKey, isFieldSelected } from "../../reducers/respondents"
import * as surveyActions from "../../actions/survey"
import * as projectActions from "../../actions/project"
import * as questionnairesActions from "../../actions/questionnaires"
import values from "lodash/values"
import {
  CardTable,
  UntitledIfEmpty,
  Modal,
  SortableHeader,
  Tooltip,
  PagingFooter,
  MainAction,
} from "../ui"
import RespondentRow from "./RespondentRow"
import * as routes from "../../routes"
import { modeLabel } from "../../questionnaire.mode"
import find from "lodash/find"
import flatten from "lodash/flatten"
import { translate } from "react-i18next"
import classNames from "classnames/bind"
import RespondentsFilter from "./RespondentsFilter"
import { uniqueId } from "lodash"

type Props = {
  t: Function,
  projectId: number,
  surveyId: number,
  survey: Survey,
  project: Project,
  questionnaires: { [id: any]: Questionnaire },
  respondents: { [id: any]: Respondent },
  order: any[],
  userLevel: string,
  pageSize: number,
  pageNumber: number,
  totalCount: number,
  sortBy: any,
  sortAsc: any,
  startIndex: number,
  endIndex: number,
  surveyActions: any,
  projectActions: any,
  questionnairesActions: any,
  actions: any,
  router: Object,
  filter: string,
  q: string,
  fields: Array<Object>,
  selectedFields: Array<string>,
  respondentsFiles: { files: SurveyFiles },
}

type State = {
  shownFile: ?string,
  filesFetchTimer: ?IntervalID,
}

class RespondentIndex extends Component<Props, State> {
  toggleResultsLink: Function
  toggleIncentivesLink: Function
  toggleInteractionsLink: Function
  toggleDispositionHistoryLink: Function
  refreshResultsLink: Function
  refreshIncentivesLink: Function
  refreshInteractionsLink: Function
  refreshDispositionHistoryLink: Function
  columnPickerModalId: string
  timeFormatter: Function

  constructor(props) {
    super(props)
    this.state = { shownFile: null , filesFetchTimer: null }
    this.toggleResultsLink = this.toggleResultsLink.bind(this)
    this.toggleIncentivesLink = this.toggleIncentivesLink.bind(this)
    this.toggleInteractionsLink = this.toggleInteractionsLink.bind(this)
    this.toggleDispositionHistoryLink = this.toggleDispositionHistoryLink.bind(this)
    this.refreshResultsLink = this.refreshResultsLink.bind(this)
    this.refreshIncentivesLink = this.refreshIncentivesLink.bind(this)
    this.refreshInteractionsLink = this.refreshInteractionsLink.bind(this)
    this.refreshDispositionHistoryLink = this.refreshDispositionHistoryLink.bind(this)
    this.timeFormatter = this.timeFormatter.bind(this)
    this.columnPickerModalId = uniqueId("column-picker-modal-id_")
  }

  componentDidMount() {
    const { projectId, surveyId, projectActions, surveyActions, questionnairesActions, q } =
      this.props
    if (projectId && surveyId) {
      projectActions.fetchProject(projectId)
      surveyActions.fetchSurvey(projectId, surveyId)
      questionnairesActions.fetchQuestionnaires(projectId)
      this.fetchRespondents(1, q)
    }
  }

  componentWillUnmount() {
    const timer = this.state.filesFetchTimer
    if (timer) {
      clearInterval(timer)
      this.setState({filesFetchTimer: null})
    }
  }

  fetchRespondents(pageNumber = 1, overrideFilter = null) {
    const { projectId, surveyId, pageSize, filter, sortBy, sortAsc } = this.props
    const _filter = overrideFilter == null ? filter : overrideFilter
    this.props.actions.fetchRespondents(
      projectId,
      surveyId,
      pageSize,
      pageNumber,
      _filter,
      sortBy,
      sortAsc
    )
  }

  timeFormatter(number, unit, suffix, date, defaultFormatter) {
    const { t } = this.props

    switch (unit) {
      case "second":
        return t("{{count}} seconds ago", { count: number })
      case "minute":
        return t("{{count}} minutes ago", { count: number })
      case "hour":
        return t("{{count}} hours ago", { count: number })
      case "day":
        return t("{{count}} days ago", { count: number })
      case "week":
        return t("{{count}} weeks ago", { count: number })
      case "month":
        return t("{{count}} months ago", { count: number })
      case "year":
        return t("{{count}} years ago", { count: number })
    }
  }

  fetchFilesStatus() {
    const { projectId, surveyId, filter } = this.props

    // FIXME: don't fetch if we're already fetching
    this.props.surveyActions.fetchRespondentsFilesStatus(projectId, surveyId, filter)
  }

  showDownloadsModal() {
    this.fetchFilesStatus()
    if (this.state.filesFetchTimer == null) {
      const filesFetchTimer = setInterval(() => {
        this.fetchFilesStatus()
      }, 20_000);
      this.setState({ filesFetchTimer })
    }
    $('#downloadCSV').modal("open")
  }

  nextPage() {
    const { pageNumber } = this.props
    this.fetchRespondents(pageNumber + 1)
  }

  previousPage() {
    const { pageNumber } = this.props
    this.fetchRespondents(pageNumber - 1)
  }

  resultsFileUrl(applyUserFilter = false) {
    const { projectId, surveyId, filter } = this.props
    const q = (applyUserFilter && filter) || null
    return api.resultsFileUrl(projectId, surveyId, q)
  }

  dispositionHistoryFileUrl() {
    const { projectId, surveyId } = this.props
    return api.dispositionHistoryFileUrl(projectId, surveyId)
  }

  incentivesFileUrl() {
    const { projectId, surveyId } = this.props
    return api.incentivesFileUrl(projectId, surveyId)
  }

  interactionsFileUrl() {
    const { projectId, surveyId } = this.props
    return api.interactionsFileUrl(projectId, surveyId)
  }

  sortBy(name) {
    const { projectId, surveyId } = this.props
    this.props.actions.sortRespondentsBy(projectId, surveyId, name)
  }

  getModes(surveyModes) {
    return [...new Set(flatten(surveyModes))]
  }

  resultsAccessLink() {
    const { survey } = this.props
    return find(survey.links, (link) => link.name == `survey/${survey.id}/results`)
  }

  incentivesAccessLink() {
    const { survey } = this.props
    return find(survey.links, (link) => link.name == `survey/${survey.id}/incentives`)
  }

  interactionsAccessLink() {
    const { survey } = this.props
    return find(survey.links, (link) => link.name == `survey/${survey.id}/interactions`)
  }

  dispositionHistoryAccessLink() {
    const { survey } = this.props
    return find(survey.links, (link) => link.name == `survey/${survey.id}/disposition_history`)
  }

  toggleResultsLink(link) {
    const { projectId, surveyId, surveyActions } = this.props
    if (link) {
      surveyActions.deleteResultsLink(projectId, surveyId, link)
    } else {
      surveyActions.createResultsLink(projectId, surveyId)
    }
  }

  toggleIncentivesLink(link) {
    const { projectId, surveyId, surveyActions } = this.props
    if (link) {
      surveyActions.deleteIncentivesLink(projectId, surveyId, link)
    } else {
      surveyActions.createIncentivesLink(projectId, surveyId)
    }
  }

  toggleInteractionsLink(link) {
    const { projectId, surveyId, surveyActions } = this.props
    if (link) {
      surveyActions.deleteInteractionsLink(projectId, surveyId, link)
    } else {
      surveyActions.createInteractionsLink(projectId, surveyId)
    }
  }

  toggleDispositionHistoryLink(link) {
    const { projectId, surveyId, surveyActions } = this.props
    if (link) {
      surveyActions.deleteDispositionHistoryLink(projectId, surveyId, link)
    } else {
      surveyActions.createDispositionHistoryLink(projectId, surveyId)
    }
  }

  refreshResultsLink(link) {
    const { projectId, surveyId, surveyActions } = this.props
    surveyActions.refreshResultsLink(projectId, surveyId, link)
  }

  refreshIncentivesLink(link) {
    const { projectId, surveyId, surveyActions } = this.props
    surveyActions.refreshIncentivesLink(projectId, surveyId, link)
  }

  refreshInteractionsLink(link) {
    const { projectId, surveyId, surveyActions } = this.props
    surveyActions.refreshInteractionsLink(projectId, surveyId, link)
  }

  refreshDispositionHistoryLink(link) {
    const { projectId, surveyId, surveyActions } = this.props
    surveyActions.refreshDispositionHistoryLink(projectId, surveyId, link)
  }

  generateResults(filter) {
    const { projectId, surveyId, surveyActions } = this.props
    surveyActions.generateResultsFile(projectId, surveyId, filter)
  }

  generateIncentives() {
    const { projectId, surveyId, surveyActions } = this.props
    surveyActions.generateIncentivesFile(projectId, surveyId)
  }

  generateInteractions() {
    const { projectId, surveyId, surveyActions } = this.props
    surveyActions.generateInteractionsFile(projectId, surveyId)
  }

  generateDispositionHistory() {
    const { projectId, surveyId, surveyActions } = this.props
    surveyActions.generateDispositionHistoryFile(projectId, surveyId)
  }

  copyLink(link) {
    try {
      window.getSelection().selectAllChildren(link)
      document.execCommand("copy")
      window.getSelection().collapse(document.getElementsByTagName("body")[0], 0)

      window.Materialize.toast("Copied!", 3000)
    } catch (err) {
      window.Materialize.toast("Oops, unable to copy!", 3000)
    }
  }

  downloadLink(link, onChange, refresh, name) {
    const { project, t } = this.props

    return (
      <div className="access-link">
        {!project.readOnly ? (
          <div className="switch">
            <label>
              <input type="checkbox" checked={link != null} onChange={() => onChange(link)} />
              <span className="lever" />
              <span className="label">{t("Public link")}{link == null ? "" : ":"}</span>
            </label>
          </div>
        ) : (
          ""
        )}
        {link != null ? (
          <div className="link truncate">
            <span ref={name}>{link.url}</span>
            <div className="buttons">
              {!project.readOnly ? (
                <Tooltip text="Regenerate link">
                  <a className="btn-icon-grey" onClick={refresh}>
                    <i className="material-icons">refresh</i>
                  </a>
                </Tooltip>
              ) : (
                ""
              )}
              <Tooltip text="Copy to clipboard">
                <a className="btn-icon-grey" onClick={() => this.copyLink(this.refs[name])}>
                  <i className="material-icons">content_copy</i>
                </a>
              </Tooltip>
            </div>
          </div>
        ) : (
          ""
        )}
      </div>
    )
  }

  responsesByField(respondents) {
    let responsesByField = {}
    for (let respondentId in respondents) {
      if (respondents.hasOwnProperty(respondentId)) {
        const responses = respondents[respondentId].responses
        for (let responseField in responses) {
          if (responses.hasOwnProperty(responseField)) {
            if (!responsesByField[responseField]) {
              responsesByField[responseField] = []
            }
            responsesByField[responseField].push(responses[responseField])
          }
        }
      }
    }
    return responsesByField
  }

  numericFields(respondents) {
    let responsesByField = this.responsesByField(respondents)
    let numericFields = []
    for (let responseField in responsesByField) {
      if (responsesByField.hasOwnProperty(responseField)) {
        if (responsesByField[responseField].every((response) => !isNaN(response))) {
          numericFields.push(responseField)
        }
      }
    }
    return numericFields
  }

  fieldIsNumeric(numericFields, filterField) {
    return numericFields.some((field) => field == filterField)
  }

  toggleFile(fileId, event) {
    event.preventDefault()
    this.setState({ shownFile: this.state.shownFile == fileId ? null : fileId })
  }

  downloadItem(id) {
    const { t, totalCount, filter, respondentsFiles } = this.props
    const { shownFile } = this.state
    const currentFile = shownFile == id
    let item: ?{
      title: String,
      description: String,
      disabledText?: String,
      disabled?: boolean,
      downloadLink: any,
      fileUrl: string,
      onGenerate: Function,
    } = null
    const fileStatus = currentFile ? respondentsFiles.files?.[id] : null
    switch (id) {
      case "respondents_filtered":
        item = {
          title: t("Filtered survey results"),
          description: t(
            "{{totalCount}} respondents resulting from applying the current filter: {{filter}}",
            { totalCount, filter }
          ),
          downloadLink: null,
          fileUrl: this.resultsFileUrl(true),
          onGenerate: () => this.generateResults(filter),
        }
        break
      case "respondents_results":
        item = {
          title: t("Survey results"),
          description: t(
            "One line per respondent, with a column for each variable in the questionnaire, including disposition and timestamp"
          ),
          downloadLink: this.downloadLink(
            this.resultsAccessLink(),
            this.toggleResultsLink,
            this.refreshResultsLink,
            "resultsLink"
          ),
          fileUrl: this.resultsFileUrl(),
          onGenerate: () => this.generateResults(),
        }
        break
      case "disposition_history":
        item = {
          title: t("Disposition History"),
          description: t(
            "One line for each time the disposition of a respondent changed, including the timestamp"
          ),
          downloadLink: this.downloadLink(
            this.dispositionHistoryAccessLink(),
            this.toggleDispositionHistoryLink,
            this.refreshDispositionHistoryLink,
            "dispositionHistoryLink"
          ),
          fileUrl: this.dispositionHistoryFileUrl(),
          onGenerate: () => this.generateDispositionHistory(),
        }
        break
      case "incentives":
        const disabled = !this.props.survey.incentivesEnabled
        item = {
          title: t("Incentives file"),
          description: t(
            "One line for each respondent that completed the survey, including the experiment version and the full phone number"
          ),
          disabledText: t("Disabled because a CSV with respondent ids was uploaded"),
          disabled: disabled,
          downloadLink: this.downloadLink(
            this.incentivesAccessLink(),
            this.toggleIncentivesLink,
            this.refreshIncentivesLink,
            "incentivesLink"
          ),
          fileUrl: this.incentivesFileUrl(),
          onGenerate: () => this.generateIncentives(),
        }
        break
      case "interactions":
        item = {
          title: t("Interactions"),
          description: t(
            "One line per respondent interaction, with a column describing the action type and data, including disposition and timestamp"
          ),
          downloadLink: this.downloadLink(
            this.interactionsAccessLink(),
            this.toggleInteractionsLink,
            this.refreshInteractionsLink,
            "interactionsLink"
          ),
          fileUrl: this.interactionsFileUrl(),
          onGenerate: () => this.generateInteractions(),
        }
    }

    if (item == null) {
      return null
    } else {
      const disabled = item.disabled

      const fileExists = !!fileStatus?.created_at

      const downloadButtonTooltip = fileExists ? t("Download file") : t("File not yet generated")
      const downloadButtonClass = fileExists ? "black-text" : "grey-text"
      const downloadButtonLink = fileExists ? item.fileUrl : null
      const createdAtLabel = fileExists ? <TimeAgo date={(fileStatus?.created_at || 0) * 1000} formatter={this.timeFormatter} /> : null

      const fileCreating = !!fileStatus?.creating
      const generateButtonClass = fileCreating ? "grey-text spinning" : "black-text"
      const generateButtonOnClick = fileCreating ? null : item.onGenerate
      const generatingFileLabel = fileCreating ? "Generating..." : ""

      // TODO: we could avoid generating the whole section for files that are not the current one
      const downloadButton = !currentFile ? null : (
        <div className="file-download">
          <Tooltip text={downloadButtonTooltip}>
            <a className={downloadButtonClass} href={downloadButtonLink}>
              <i className="material-icons">get_app</i>
            </a>
          </Tooltip>
          <span className="">{t("Download last generated file")}</span>
          <span className="grey-text file-generation">
            { createdAtLabel }
            { generatingFileLabel }
            <Tooltip text={t("Regenerate file")}>
              <a className={generateButtonClass} onClick={generateButtonOnClick}>
                <i className="material-icons">refresh</i>
              </a>
            </Tooltip>
          </span>
        </div>
      )

      return (
        <li disabled={disabled} className="collection-item">
          <div style={{position: 'relative'}}>
          <a href="#!" className="download" onClick={(e) => this.toggleFile(id, e)}>
            <div disabled={disabled} className="button">
              <i className="material-icons">{currentFile ? "expand_more" : "chevron_right"}</i>
            </div>
          </a>
          <div className="file-section">
            <p disabled={disabled} className="title">
              <b>{item.title}</b>
            </p>
            <p>{item.description}</p>
            {disabled ? <p className="disabled-clarification">{item.disabledText}</p> : null}
            { currentFile ?
              <div className="download-section">
                { item.downloadLink }
                { downloadButton }
              </div>
              : ""
            }
          </div></div>
        </li>
      )
    }
  }

  onFilterChange(value) {
    const { router, projectId, surveyId, actions } = this.props
    router.push(routes.surveyRespondents(projectId, surveyId, value))
    actions.updateRespondentsFilter(projectId, surveyId, value)
  }

  respondentsFilter() {
    const { q } = this.props
    return <RespondentsFilter defaultValue={q} onChange={(value) => this.onFilterChange(value)} />
  }

  downloadModal() {
    const { userLevel, t, filter } = this.props
    const ownerOrAdmin = userLevel == "owner" || userLevel == "admin"

    return (
      <Modal id="downloadCSV" confirmationText="Download CSV" card>
        <div className="card-title header">
          <h5>{t("Download CSV")}</h5>
          <p>{t("Choose the data you want to download")}</p>
        </div>
        <ul className="collection repondents-index-modal">
          {filter ? this.downloadItem("respondents_filtered") : null}
          {this.downloadItem("respondents_results")}
          {this.downloadItem("disposition_history")}
          {ownerOrAdmin ? this.downloadItem("incentives") : null}
          {ownerOrAdmin ? this.downloadItem("interactions") : null}
        </ul>
      </Modal>
    )
  }

  renderHeader({ displayText, type, key, sortable, dataType }) {
    const { sortBy, sortAsc } = this.props
    const uniqueKey = fieldUniqueKey(type, key)
    let className = classNames({
      thNumber: dataType === "number",
      thDate: dataType === "date",
    })

    if (sortable) {
      return (
        <SortableHeader
          text={displayText}
          property={key}
          sortBy={sortBy}
          sortAsc={sortAsc}
          onClick={() => this.sortBy(key)}
          key={uniqueKey}
          className={className}
        />
      )
    } else {
      return (
        <th className={className} key={uniqueKey}>
          {displayText}
        </th>
      )
    }
  }

  isFieldSelected(uniqueKey) {
    const { selectedFields } = this.props
    return isFieldSelected(selectedFields, uniqueKey)
  }

  renderColumnPickerModal() {
    const { fields, t } = this.props
    const onInputChange = (uniqueKey, newValue) =>
      this.props.actions.setRespondentsFieldSelection(uniqueKey, newValue)

    return (
      <Modal id={this.columnPickerModalId} card className={"column-picker"}>
        <div className="card-title header">
          <h5>{t("Column picker")}</h5>
          <p>{t("Selected columns")}</p>
        </div>
        <ul className="collection repondents-index-modal">
          {fields.map((field) => {
            const uniqueKey = fieldUniqueKey(field.type, field.key)
            const id = `column_picker_${uniqueKey}`
            const checked = this.isFieldSelected(uniqueKey)
            return (
              <li className="collection-item" key={id}>
                <input
                  className="filled-in"
                  id={id}
                  type="checkbox"
                  checked={checked}
                  onChange={(event) => onInputChange(uniqueKey, !checked)}
                />
                <label htmlFor={id}>{field.displayText}</label>
              </li>
            )
          })}
        </ul>
      </Modal>
    )
  }

  renderTitleWithColumnsPickerButton() {
    const { t, totalCount } = this.props
    const title = t("{{count}} respondent", { count: totalCount })
    return (
      <div className="valign-wrapper">
        <div>{title}</div>
        <button
          className="transparent-button valign-wrapper"
          onClick={() => $(`#${this.columnPickerModalId}`).modal("open")}
        >
          <i className="material-icons">more_vert</i>
        </button>
      </div>
    )
  }

  renderFooter() {
    const { startIndex, endIndex, totalCount, pageSize } = this.props
    return (
      <PagingFooter
        {...{ startIndex, endIndex, pageSize, totalCount }}
        onPreviousPage={() => this.previousPage()}
        onNextPage={() => this.nextPage()}
        onPageSizeChange={(pageSize) => this.changePageSize(pageSize)}
        pageSizeOptions={[5, 10, 20, 50]}
      />
    )
  }

  fieldDataType(field, isNumeric) {
    return field.type == "response" && isNumeric ? "number" : field.dataType
  }

  renderHeaders(numericFields) {
    const { fields } = this.props
    const selectedFields = fields.filter((field) =>
      this.isFieldSelected(fieldUniqueKey(field.type, field.key))
    )
    return (
      <tr>
        {selectedFields.length ? (
          selectedFields.map((field) =>
            this.renderHeader({
              displayText: field.displayText,
              key: field.key,
              sortable: field.sortable,
              type: field.type,
              dataType: this.fieldDataType(field, this.fieldIsNumeric(numericFields, field.key)),
            })
          )
        ) : (
          // If no field is selected, render an empty header
          <th className="center">-</th>
        )}
      </tr>
    )
  }

  changePageSize(pageSize) {
    const { projectId, surveyId, actions } = this.props
    if (pageSize != this.props.pageSize) {
      actions.changePageSize(projectId, surveyId, pageSize)
    }
  }

  render() {
    const { project, survey, questionnaires, order, t, selectedFields } = this.props
    const loading = !project || !survey || !this.props.respondents || !questionnaires

    if (loading) {
      return <div>{t("Loading...")}</div>
    }

    const hasComparisons = survey.comparisons.length > 0

    /* jQuery extend clones respondents object, in order to build an easy to manage structure without
    modify state */

    const respondents = generateResponsesDictionaryFor($.extend(true, {}, this.props.respondents))
    let numericFields = this.numericFields(respondents)

    const respondentsList: Respondent[] = values(respondents)

    function generateResponsesDictionaryFor(rs) {
      Object.keys(rs).forEach((respondentId, _) => {
        rs[respondentId].responses = responsesDictionaryFrom(rs[respondentId].responses)
      })
      return rs
    }

    function responsesDictionaryFrom(responseArray) {
      const res = {}
      for (const key in responseArray) {
        res[responseArray[key].name] = responseArray[key].value
      }
      return res
    }

    function hasResponded(rs, respondentId, fieldName) {
      return Object.keys(rs[respondentId].responses).includes(fieldName)
    }

    function responseOf(rs, respondentId, fieldName) {
      return hasResponded(rs, respondentId, fieldName) ? rs[respondentId].responses[fieldName] : "-"
    }

    const responseKeys = this.props.fields
      .filter((field) => field.type == "response")
      .map((field) => field.key)

    const fixedFieldsCount = this.props.fields.filter((field) => field.type == "fixed").length

    let colspan = responseKeys.length + fixedFieldsCount

    return (
      <div className="white">
        <div
          dangerouslySetInnerHTML={{
            __html: "<style> body { overflow-y: auto !important; color: black}</style>",
          }}
        />
        <MainAction text="Downloads" icon="get_app" onClick={() => this.showDownloadsModal()} />
        {this.downloadModal()}
        {this.renderColumnPickerModal()}
        {this.respondentsFilter()}
        <CardTable
          title={this.renderTitleWithColumnsPickerButton()}
          footer={this.renderFooter()}
          tableScroll
        >
          <thead>{this.renderHeaders(numericFields)}</thead>
          <tbody>
            {order.map((respondentId, index) => {
              const respondent = respondentsList.find((r) => r.id == respondentId)
              if (!respondent)
                return (
                  <tr key={-index} className="empty-row">
                    <td colSpan={colspan} />
                  </tr>
                )

              let variantColumn = null
              if (hasComparisons) {
                let variantValue
                let questionnaire
                if (
                  respondent.questionnaireId &&
                  respondent.mode &&
                  (questionnaire = questionnaires[respondent.questionnaireId])
                ) {
                  const questionnaireName = (
                    <UntitledIfEmpty
                      text={questionnaire.name}
                      emptyText={t("Untitled questionnaire")}
                    />
                  )
                  variantValue = (
                    <span>
                      {questionnaireName} - {modeLabel(respondent.mode)}
                    </span>
                  )
                } else {
                  variantValue = "-"
                }

                variantColumn = <td>{variantValue}</td>
              }

              const responses = responseKeys.map((responseKey) => {
                return {
                  name: responseKey,
                  value: responseOf(respondents, respondent.id, responseKey),
                }
              })
              return (
                <RespondentRow
                  cellClassNames={(fieldName) =>
                    classNames({
                      tdNowrap: true,
                      tdNumber: this.fieldIsNumeric(numericFields, fieldName),
                    })
                  }
                  key={index}
                  respondent={respondent}
                  responses={responses}
                  variantColumn={variantColumn}
                  surveyModes={this.getModes(survey.mode)}
                  selectedFields={selectedFields}
                />
              )
            })}
          </tbody>
        </CardTable>
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  const { project, survey, questionnaires, respondents, respondentsFiles } = state
  const { page, sortBy, sortAsc, order, filter, items, fields, selectedFields } = respondents
  const { number: pageNumber, size: pageSize, totalCount } = page
  const { projectId, surveyId } = ownProps.params
  const startIndex = (pageNumber - 1) * pageSize + 1
  const endIndex = Math.min(startIndex + pageSize - 1, totalCount)

  return {
    projectId,
    surveyId,
    q: ownProps.location.query.q || "",
    survey: survey.data,
    project: project.data,
    questionnaires: questionnaires.items,
    respondents: items,
    respondentsFiles,
    order,
    userLevel: project.data ? project.data.level : "",
    pageNumber,
    pageSize,
    startIndex,
    endIndex,
    totalCount,
    sortBy,
    sortAsc,
    filter,
    fields: fields || [],
    selectedFields: selectedFields || [],
  }
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch),
  surveyActions: bindActionCreators(surveyActions, dispatch),
  projectActions: bindActionCreators(projectActions, dispatch),
  questionnairesActions: bindActionCreators(questionnairesActions, dispatch),
})

export default translate()(connect(mapStateToProps, mapDispatchToProps)(RespondentIndex))
