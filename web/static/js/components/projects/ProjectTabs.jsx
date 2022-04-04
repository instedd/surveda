import React, { Component, PropTypes } from "react"
import { connect } from "react-redux"
import { withRouter } from "react-router"
import { Tabs, TabLink, Dropdown, DropdownItem, ConfirmationModal } from "../ui"
import * as routes from "../../routes"
import ColourSchemeModal from "./ColourSchemeModal"
import { leaveProject } from "../../api"
import { translate } from "react-i18next"
import { isProjectReadOnly } from "../../reducers/project"

class ProjectTabs extends Component {
  openColorSchemePopup(e) {
    $("#colourSchemeModal").modal("open")
  }

  leaveProject(event, projectId) {
    const { router, t } = this.props
    event.preventDefault()

    const leaveConfirmationModal: ConfirmationModal = this.refs.leaveConfirmationModal
    leaveConfirmationModal.open({
      modalText: (
        <span>
          <p>
            <b>{t("Are you sure?")}</b>
            <br />
            {t("You won't be able to access this project anymore")}
          </p>
        </span>
      ),
      onConfirm: () => {
        leaveProject(projectId).then(() => router.push(routes.projects))
      },
    })
  }

  render() {
    const { projectId, project, readOnly, t, fetchedProject } = this.props
    const changeColorScheme = !readOnly ? (
      <DropdownItem>
        <a onClick={(e) => this.openColorSchemePopup(e)}>
          <i className="material-icons">palette</i>
          {t("Change color scheme")}
        </a>
      </DropdownItem>
    ) : null

    // Nothing to display in 'more' tab if user is owner and project is archived
    let more =
      !fetchedProject || (fetchedProject && project.owner && readOnly) ? null : (
        <div className="col">
          <Dropdown
            className="options"
            dataBelowOrigin={false}
            label={<i className="material-icons">more_vert</i>}
          >
            <DropdownItem className="dots">
              <i className="material-icons">more_vert</i>
            </DropdownItem>
            {changeColorScheme}
            {fetchedProject && !project.owner ? (
              <DropdownItem>
                <a onClick={(e) => this.leaveProject(e, projectId)}>
                  <i className="material-icons">exit_to_app</i>
                  {t("Leave project")}
                </a>
              </DropdownItem>
            ) : (
              ""
            )}
          </Dropdown>
        </div>
      )

    return (
      <div>
        <Tabs id="project_tabs" more={more}>
          <TabLink tabId="project_tabs" to={routes.surveyIndex(projectId)}>
            {t("Surveys")}
          </TabLink>
          <TabLink tabId="project_tabs" to={routes.questionnaireIndex(projectId)}>
            {t("Questionnaires")}
          </TabLink>
          <TabLink tabId="project_tabs" to={routes.collaboratorIndex(projectId)}>
            {t("Collaborators")}
          </TabLink>
          <TabLink tabId="project_tabs" to={routes.activityIndex(projectId)}>
            {t("Activity")}
          </TabLink>
        </Tabs>
        <ColourSchemeModal modalId="colourSchemeModal" />
        <ConfirmationModal
          modalId="leave_project"
          ref="leaveConfirmationModal"
          confirmationText={t("LEAVE")}
          header={t("Leave project")}
          showCancel
        />
      </div>
    )
  }

  componentDidMount() {
    $("project-options-dropdown-trigger").dropdown()
  }
}

ProjectTabs.propTypes = {
  t: PropTypes.func,
  projectId: PropTypes.any.isRequired,
  router: PropTypes.object.isRequired,
  project: PropTypes.object,
  fetchedProject: PropTypes.bool,
  readOnly: PropTypes.bool,
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  fetchedProject: state.project && !state.project.fetching,
  project: state.project.data,
  readOnly: isProjectReadOnly(state),
})

export default translate()(withRouter(connect(mapStateToProps)(ProjectTabs)))
