import React, { Component, PropTypes } from "react"
import { connect } from "react-redux"
import { withRouter } from "react-router"
import TimezoneAutocomplete from "../timezones/TimezoneAutocomplete"
import * as actions from "../../actions/projects"
import * as projectActions from "../../actions/project"
import merge from "lodash/merge"
import pick from "lodash/pick"
import { translate } from "react-i18next"
import { isProjectReadOnly } from "../../reducers/project"

class ProjectSettings extends Component {
  componentDidMount() {
    if (!this.props.isLoading) {
      this.setStateFromProject()
    }
  }

  componentDidUpdate(prevProps) {
    if (prevProps.isLoading && !this.props.isLoading) {
      this.setStateFromProject()
    }
    if (prevProps.isSaving && !this.props.isSaving && Object.keys(this.props.errors).length == 0) {
      this.initialState = JSON.parse(JSON.stringify(this.state))
      this.forceUpdate() // because we didn't touch the state
    }
  }

  setStateFromProject() {
    const { project } = this.props
    var state = {
      name: project.name,
      timezone: project.timezone,
      colourScheme: project.colourScheme,
      initialSuccessRate: project.initialSuccessRate || "",
      eligibilityRate: project.eligibilityRate || "",
      responseRate: project.responseRate || "",
      validRespondentRate: project.validRespondentRate || "",
      detailedRates: project.eligibilityRate != null,
      archiveAction: project.readOnly ? "unarchive" : "archive",
    }
    this.initialState = JSON.parse(JSON.stringify(state))
    this.setState(state)
  }

  toggleDetailedRates() {
    const { detailedRates } = this.state
    this.setState({ detailedRates: !detailedRates })
  }

  saveProjectSettings() {
    const { dispatch, project } = this.props
    const changes = merge({}, project, {
      name: this.state.name,
      timezone: this.state.timezone,
      colourScheme: this.state.colourScheme,
      initialSuccessRate: parseFloat(this.state.initialSuccessRate, 10) || null,
      eligibilityRate: parseFloat(this.state.eligibilityRate, 10) || null,
      responseRate: parseFloat(this.state.responseRate, 10) || null,
      validRespondentRate: parseFloat(this.state.validRespondentRate, 10) || null,
    })
    dispatch(projectActions.updateProject(changes))
  }

  updateInitialSuccessRate() {
    const { eligibilityRate, responseRate, validRespondentRate } = this.state

    if (eligibilityRate && responseRate && validRespondentRate) {
      const isr = (eligibilityRate * responseRate * validRespondentRate).toFixed(4)
      this.setState({ initialSuccessRate: isr })
    } else {
      this.setState({ initialSuccessRate: "" })
    }
  }

  archiveOrUnarchive(archived: boolean) {
    const { dispatch, project } = this.state
    const { archiveAction } = this.state
    dispatch(actions.archiveOrUnarchive(project, archiveAction))
    this.setState({ archiveAction: archiveAction == "archive" ? "unarchive" : "archive" })
  }

  spanErrors(field) {
    const { errors } = this.props

    if (errors[field]) {
      return (
        <span className="error">
          {errors[field].map((error) => (
            <div key={error}>{error}</div>
          ))}
        </span>
      )
    } else {
      return null
    }
  }

  updateRate(newRate) {
    this.setState(newRate, this.updateInitialSuccessRate)
  }

  renderDetailedRates() {
    return (
      <div>
        <div className="col s3" id="eligibilityRate">
          <label className="gray-text">Elegibility rate</label>
          <input
            type="number"
            step="0.01"
            min="0"
            max="1"
            value={this.state.eligibilityRate}
            disabled={this.props.readOnly}
            onInput={(e) => this.updateRate({ eligibilityRate: e.target.value })}
            onChange={(e) => this.updateRate({ eligibilityRate: e.target.value })}
          />
          {this.spanErrors("eligibilityRate")}
        </div>
        <div className="col s3" id="responseRate">
          <label className="gray-text">Response rate</label>
          <input
            type="number"
            step="0.01"
            min="0"
            max="1"
            value={this.state.responseRate}
            disabled={this.props.readOnly}
            onInput={(e) => this.updateRate({ responseRate: e.target.value })}
            onChange={(e) => this.updateRate({ responseRate: e.target.value })}
          />
          {this.spanErrors("responseRate")}
        </div>
        <div className="col s3" id="validRespondentRate">
          <label className="gray-text">Valid respondent rate</label>
          <input
            type="number"
            step="0.01"
            min="0"
            max="1"
            value={this.state.validRespondentRate}
            disabled={this.props.readOnly}
            onInput={(e) => this.updateRate({ validRespondentRate: e.target.value })}
            onChange={(e) => this.updateRate({ validRespondentRate: e.target.value })}
          />
          {this.spanErrors("validRespondentRate")}
        </div>
      </div>
    )
  }

  render() {
    const { t, readOnly, isLoading } = this.props

    if (isLoading || !this.state) {
      return <div>{t("Loading project...")}</div>
    }

    const { name, timezone, colourScheme, initialSuccessRate, detailedRates, archiveAction } =
      this.state

    const inputProjectName = (
      <div>
        <label className="gray-text">Name</label>
        <input
          type="text"
          value={name}
          readOnly={readOnly}
          onChange={(e) => this.setState({ name: e.target.value })}
        />
      </div>
    )

    const inputTimeZone = (
      <div>
        <TimezoneAutocomplete
          selectedTz={timezone}
          readOnly={readOnly}
          onChange={(timezone) => this.setState({ timezone: timezone })}
        />
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

    const inputRates = (
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
              readOnly={detailedRates}
              onInput={(e) => this.setState({ initialSuccessRate: e.target.value })}
              onChange={(e) => this.setState({ initialSuccessRate: e.target.value })}
            />
            {this.spanErrors("initialSuccessRate")}
          </div>
          {detailedRates && this.renderDetailedRates()}
        </div>
        <div className="row">
          <div>
            <input
              type="checkbox"
              id="projectDetailedRates"
              label={this.props.t("Detailed rates")}
              checked={detailedRates}
              disabled={readOnly}
              onChange={(e) => this.toggleDetailedRates()}
            />
            <label htmlFor="projectDetailedRates">Enter detailed values</label>
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
            disabled={readOnly || !this.hasChanged() || this.props.isSaving}
            onClick={() => this.saveProjectSettings()}
          />
        </div>
        <div className="col">
          <input
            type="button"
            value="Cancel"
            className="btn-flat"
            onClick={() => this.setState(this.initialState)}
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
            {inputRates}
            {actionsButtons}
          </div>
        </div>
      </div>
    )
  }

  hasChanged() {
    const fields = [
      "name",
      "timezone",
      "colourScheme",
      "initialSuccessRate",
      "eligibilityRate",
      "validRespondentRate",
      "detailedRates",
    ]
    return (
      JSON.stringify(pick(this.state, fields)) !== JSON.stringify(pick(this.initialState, fields))
    )
  }
}

ProjectSettings.propTypes = {
  t: PropTypes.func,
  projectId: PropTypes.any.isRequired,
  router: PropTypes.object.isRequired,
  project: PropTypes.object,
  readOnly: PropTypes.bool,
  isLoading: PropTypes.bool,
  isSaving: PropTypes.bool,
  dispatch: PropTypes.func,
  errors: PropTypes.object,
}

const mapStateToProps = (state, ownProps) => {
  return {
    projectId: ownProps.params.projectId,
    project: state.project.data,
    errors: state.project.errors || {},
    readOnly: isProjectReadOnly(state),
    isLoading: state.project.fetching,
    isSaving: state.project.saving,
  }
}

export default translate()(withRouter(connect(mapStateToProps)(ProjectSettings)))
