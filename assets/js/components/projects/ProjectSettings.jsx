import React, { Component, PropTypes } from "react"
import { connect } from "react-redux"
import { bindActionCreators } from "redux"
import { withRouter } from "react-router"
import { orderedItems } from "../../reducers/collection"
import { InputWithLabel } from "../ui"
import ColourSchemeModal from "./ColourSchemeModal"
import TimezoneAutocomplete from "../timezones/TimezoneAutocomplete"
import * as actions from "../../actions/projects"
import * as projectActions from "../../actions/project"
import { updateProject, fetchProject, updateProjectArchived } from "../../api"
import merge from "lodash/merge"
import dateformat from "dateformat"
import { translate } from "react-i18next"
import { isProjectReadOnly } from "../../reducers/project"
import { ArchiveIcon } from "../ui"

class ProjectSettings extends Component {
  constructor(props) {
    super(props)
    this.state = {
      name: "",
      timezone: "",
      colourScheme: "default",
      initialSuccessRate: 0,
      eligibilityRate: 0,
      responseRate: 0,
      validRespondentRate: 0,
      detailedRates: false,
      archiveAction: "archive",
    }
  }

  fetchProjectAndSetState() {
    const { projectId, t } = this.props
    fetchProject(projectId).then((response) => {
      const project = response.entities.projects[response.result]
      this.setState({
        name: project.name,
        timezone: project.timezone,
        colourScheme: project.colourScheme,
        initialSuccessRate: project.initialSuccessRate,
        eligibilityRate: project.eligibilityRate,
        responseRate: project.responseRate,
        validRespondentRate: project.validRespondentRate,
        detailedRates: project.eligibilityRate != null,
        archiveAction: project.readOnly ? "unarchive" : "archive",
        readOnly: !project.owner,
      })
      this.initialState = this.state
      this.configureRates(this.state.detailedRates)
      this.project = project
    })
  }

  componentDidMount() {
    const { projectId, t } = this.props
    this.fetchProjectAndSetState()
  }

  changePageSize(pageSize) {
    const { projectId } = this.props
  }

  toggleDetailedRates(toggle) {
    const { projectId } = this.props
    const { detailedRates } = this.state
    this.setState({ detailedRates: !detailedRates })
    this.configureRates(!detailedRates)
  }

  configureRates(detailedRates) {
    if (detailedRates) {
      document.getElementById("initialSuccessRate").getElementsByTagName("input")[0].disabled = true
      document.getElementById("eligibilityRate").style.display = "block"
      document.getElementById("responseRate").style.display = "block"
      document.getElementById("validRespondentRate").style.display = "block"
      this.updateInitialSuccessRate()
    } else {
      document
        .getElementById("initialSuccessRate")
        .getElementsByTagName("input")[0].disabled = false
      document.getElementById("eligibilityRate").style.display = "none"
      document.getElementById("responseRate").style.display = "none"
      document.getElementById("validRespondentRate").style.display = "none"
      document.getElementById("eligibilityRate").getElementsByTagName("input")[0].value = ""
      document.getElementById("responseRate").getElementsByTagName("input")[0].value = ""
      document.getElementById("validRespondentRate").getElementsByTagName("input")[0].value = ""
      this.setState({ eligibilityRate: null, responseRate: null, validRespondentRate: null })
    }
  }

  saveProjectSettings() {
    const { dispatch, project } = this.props
    const newValues = {
      name: this.state.name,
      timezone: document.getElementsByName("timezone_id")[0].value,
      colourScheme: this.state.colourScheme,
      initialSuccessRate: parseFloat(this.state.initialSuccessRate),
      eligibilityRate: parseFloat(this.state.eligibilityRate),
      responseRate: parseFloat(this.state.responseRate),
      validRespondentRate: parseFloat(this.state.validRespondentRate),
    }
    const newProject = merge({}, project, newValues)
    updateProject(newProject).then((response) =>
      dispatch(projectActions.updateProject(response.entities.projects[response.result]))
    )
  }

  updateInitialSuccessRate() {
    const isr = (
      this.state.eligibilityRate *
      this.state.responseRate *
      this.state.validRespondentRate
    ).toFixed(4)
    this.setState({ initialSuccessRate: isr })
  }

  archiveOrUnarchive(archived: boolean) {
    const { archiveAction } = this.state
    this.project = merge({}, this.project, { archived: archiveAction == "archive" })
    updateProjectArchived(this.project)
    this.setState({ archiveAction: archiveAction == "archive" ? "unarchive" : "archive" })
  }

  render() {
    const {
      name,
      timezone,
      colourScheme,
      initialSuccessRate,
      eligibilityRate,
      responseRate,
      validRespondentRate,
      detailedRates,
      archiveAction,
      readOnly,
    } = this.state

    const { t } = this.props
    const fieldsToSave = [
      "name",
      "timezone",
      "colourScheme",
      "initialSuccessRate",
      "eligibilityRate",
      "validRespondentRate",
      "detailedRates",
    ]
    const errors = {} //this.isNew() ? {} : this.props.errors

    const setTimezone = (timezone) => this.setState({ timezone: timezone })

    const inputProjectName = (
      <div>
        <label className="gray-text">Name</label>
        <input type="text" value={name} />
      </div>
    )

    const inputTimeZone = (
      <div>
        <TimezoneAutocomplete selectedTz={timezone} readOnly={readOnly} onChange={setTimezone} />
      </div>
    )

    const inputColourScheme = (
      <div>
        <div className="card-content">
          <div className="row">
            <label className="gray-text">{t("Select color scheme")}</label>
          </div>
          <div className="row">
            <div className="col s12">
              <input
                id={`defaultScheme`}
                type="radio"
                name="toggleDefault"
                checked={colourScheme == "default"}
                disabled={readOnly}
                onChange={(e) => this.setState({ colourScheme: "default" })}
                className="with-gap"
              />
              <label className="colourScheme" htmlFor={`defaultScheme`}>
                {t("Default color scheme")}
              </label>
            </div>
          </div>
          <div className="row">
            <div className="col s12">
              <input
                id={`betterDataForHealthScheme`}
                type="radio"
                name="toggleDefault"
                checked={colourScheme == "better_data_for_health"}
                disabled={readOnly}
                onChange={(e) => this.setState({ colourScheme: "better_data_for_health" })}
                className="with-gap"
              />
              <label className="colourScheme" htmlFor={`betterDataForHealthScheme`}>
                {t("Data for health initiative")}
              </label>
            </div>
          </div>
        </div>
      </div>
    )

    const inputInitialSuccessRate = (
      <div>
        <div className="row">
          <div className="col s3" id="initialSuccessRate">
            <label className="gray-text">Initial success rate</label>
            <input
              type="number"
              step="0.01"
              min="0"
              max="1"
              value={initialSuccessRate}
              disabled={readOnly}
              onInput={(e) => this.setState({ initialSuccessRate: e.target.value })}
              onChange={(e) => this.setState({ initialSuccessRate: e.target.value })}
            />
          </div>
          <div className="col s3" id="eligibilityRate">
            <label className="gray-text">Elegibility rate</label>
            <input
              type="number"
              step="0.01"
              min="0"
              max="1"
              value={eligibilityRate}
              disabled={readOnly}
              onInput={(e) => {
                this.setState({ eligibilityRate: e.target.value })
                this.updateInitialSuccessRate()
              }}
              onChange={(e) => {
                this.setState({ eligibilityRate: e.target.value })
                this.updateInitialSuccessRate()
              }}
            />
          </div>
          <div className="col s3" id="responseRate">
            <label className="gray-text">Response rate</label>
            <input
              type="number"
              step="0.01"
              min="0"
              max="1"
              value={responseRate}
              disabled={readOnly}
              onInput={(e) => {
                this.setState({ responseRate: e.target.value })
                this.updateInitialSuccessRate()
              }}
              onChange={(e) => {
                this.setState({ responseRate: e.target.value })
                this.updateInitialSuccessRate()
              }}
            />
          </div>
          <div className="col s3" id="validRespondentRate">
            <label className="gray-text">Valid respondent rate</label>
            <input
              type="number"
              step="0.01"
              min="0"
              max="1"
              value={validRespondentRate}
              disabled={readOnly}
              onInput={(e) => {
                this.setState({ validRespondentRate: e.target.value })
                this.updateInitialSuccessRate()
              }}
              onChange={(e) => {
                this.setState({ validRespondentRate: e.target.value })
                this.updateInitialSuccessRate()
              }}
            />
          </div>
        </div>
        <div className="row">
          <div>
            <input
              type="checkbox"
              label={this.props.t("Detailed rates")}
              checked={detailedRates}
              disabled={readOnly}
            />
            <label onClick={(e) => this.toggleDetailedRates(detailedRates)}>
              Enter detailed values
            </label>
          </div>
        </div>
      </div>
    )

    const actionsButtons = (
      <div className="row">
        <div className="col">
          <input
            type="button"
            value="Save"
            className="btn blue"
            disabled={
              readOnly ||
              JSON.stringify(_.pick(this.state, fieldsToSave)) ===
                JSON.stringify(_.pick(this.initialState, fieldsToSave))
            }
            onClick={() => this.saveProjectSettings()}
          />
        </div>
        <div className="col">
          <input
            type="button"
            value="Cancel"
            className="btn-flat"
            onClick={() => window.location.reload(false)}
          />
        </div>
        <div>
          <input
            type="button"
            value={archiveAction + " project"}
            className="btn blue right"
            onClick={() => this.archiveOrUnarchive()}
          />
        </div>
      </div>
    )

    return (
      <div>
        <div className="row">
          <div className="col l8 offset-l2">
            <h4>Settings</h4>
            <br />
            {inputProjectName}
            {inputTimeZone}
            {inputColourScheme}
            {inputInitialSuccessRate}
            {actionsButtons}
          </div>
        </div>
      </div>
    )
  }
}

ProjectSettings.propTypes = {
  t: PropTypes.func,
  projectId: PropTypes.any.isRequired,
  router: PropTypes.object.isRequired,
  project: PropTypes.object,
  fetchedProject: PropTypes.bool,
  readOnly: PropTypes.bool,
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  project: state.project.data,
  readOnly: isProjectReadOnly(state),
})

export default translate()(withRouter(connect(mapStateToProps)(ProjectSettings)))
