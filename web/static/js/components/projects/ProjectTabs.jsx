import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import {Tabs, TabLink, Dropdown, DropdownItem, ConfirmationModal} from '../ui'
import * as routes from '../../routes'
import ColourSchemeModal from './ColourSchemeModal'
import { leaveProject } from '../../api'

class ProjectTabs extends Component {
  openColorSchemePopup(e) {
    $('#colourSchemeModal').modal('open')
  }

  leaveProject(event, projectId) {
    const { router } = this.props
    event.preventDefault()

    const leaveConfirmationModal: ConfirmationModal = this.refs.leaveConfirmationModal
    leaveConfirmationModal.open({
      modalText: <span>
        <p><b>Are you sure?</b><br /> You won't be able to access this project anymore</p>
      </span>,
      onConfirm: () => {
        leaveProject(projectId)
        .then(() => router.push(routes.projects))
      }
    })
  }

  render() {
    const { projectId, project, readOnly } = this.props
    const changeColorScheme = !readOnly
    ? <DropdownItem>
      <a onClick={e => this.openColorSchemePopup(e)}><i className='material-icons'>palette</i>Change color scheme</a>
    </DropdownItem> : null

    const fetchedProject = project && !project.fetching
    // Nothing to display in 'more' tab is user is owner and project is archived
    let more = !fetchedProject || (fetchedProject && project.data.owner && readOnly) ? null : (
      <div className='col'>
        <Dropdown className='options' dataBelowOrigin={false} label={<i className='material-icons'>more_vert</i>}>
          <DropdownItem className='dots'>
            <i className='material-icons'>more_vert</i>
          </DropdownItem>
          { changeColorScheme }
          { fetchedProject && !project.data.owner
            ? <DropdownItem>
              <a onClick={e => this.leaveProject(e, projectId)}><i className='material-icons'>exit_to_app</i>Leave project</a>
            </DropdownItem>
            : ''
          }
        </Dropdown>
      </div>
    )

    return (
      <div>
        <Tabs id='project_tabs' more={more}>
          <TabLink tabId='project_tabs' to={routes.surveyIndex(projectId)}>Surveys</TabLink>
          <TabLink tabId='project_tabs' to={routes.questionnaireIndex(projectId)}>Questionnaires</TabLink>
          <TabLink tabId='project_tabs' to={routes.collaboratorIndex(projectId)}>Collaborators</TabLink>
        </Tabs>
        <ColourSchemeModal modalId='colourSchemeModal' />
        <ConfirmationModal modalId='leave_project' ref='leaveConfirmationModal' confirmationText='LEAVE' header='Leave Project' showCancel />
      </div>
    )
  }

  componentDidMount() {
    $('project-options-dropdown-trigger').dropdown()
  }
}

ProjectTabs.propTypes = {
  projectId: PropTypes.any.isRequired,
  router: PropTypes.object.isRequired,
  project: PropTypes.object,
  readOnly: PropTypes.bool
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  project: state.project,
  readOnly: state.project && state.project.data ? state.project.data.readOnly : true
})

export default withRouter(connect(mapStateToProps)(ProjectTabs))
