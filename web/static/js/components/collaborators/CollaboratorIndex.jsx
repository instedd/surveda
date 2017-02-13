import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { CardTable, AddButton } from '../ui'
import InviteModal from '../collaborators/InviteModal'
import * as actions from '../../actions/collaborators'
import * as projectActions from '../../actions/project'
import * as guestActions from '../../actions/guest'

class CollaboratorIndex extends Component {
  componentDidMount() {
    const { projectId } = this.props
    if (projectId) {
      this.props.projectActions.fetchProject(projectId)
      this.props.actions.fetchCollaborators(projectId)
    }
  }

  inviteCollaborator(e) {
    e.preventDefault()
    $('#addCollaborator').modal('open')
  }

  loadCollaboratorToEdit(event, collaborator) {
    event.preventDefault()
    if (collaborator.invited) {
      this.props.guestActions.changeEmail(collaborator.email)
      this.props.guestActions.changeLevel(collaborator.role)
      this.props.guestActions.setCode(collaborator.code)
      $('#addCollaborator').modal('open')
    }
  }

  render() {
    const { collaborators, project } = this.props
    if (!collaborators) {
      return <div>Loading...</div>
    }
    const title = `${collaborators.length} ${(collaborators.length == 1) ? ' collaborator' : ' collaborators'}`

    const readOnly = !project || project.readOnly

    let addButton = null
    if (!readOnly) {
      addButton = (
        <AddButton text='Invite collaborator' onClick={(e) => this.inviteCollaborator(e)} />
      )
    }

    return (
      <div>
        {addButton}
        <InviteModal modalId='addCollaborator' modalText='The access of project collaborators will be managed through roles' header='Invite collaborators' confirmationText='accept' onConfirm={(event) => event.preventDefault()} style={{maxWidth: '800px'}} />
        <div>
          <CardTable title={title}>
            <thead>
              <tr>
                <th>Email</th>
                <th>Role</th>
              </tr>
            </thead>
            <tbody>
              { collaborators.map(c => {
                return (
                  <tr key={c.email} style={c.invited ? {cursor: 'pointer'} : {}} onClick={(e) => this.loadCollaboratorToEdit(e, c)}>
                    <td> {c.email} </td>
                    <td> {c.role + (c.invited ? ' (invited)' : '') } </td>
                  </tr>
                )
              })}
            </tbody>
          </CardTable>
        </div>
      </div>
    )
  }
}

CollaboratorIndex.propTypes = {
  projectId: PropTypes.string.isRequired,
  project: PropTypes.object,
  collaborators: PropTypes.array,
  actions: PropTypes.object.isRequired,
  guestActions: PropTypes.object.isRequired,
  projectActions: PropTypes.object.isRequired
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch),
  projectActions: bindActionCreators(projectActions, dispatch),
  guestActions: bindActionCreators(guestActions, dispatch)
})

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  project: state.project.data,
  collaborators: state.collaborators.items
})

export default connect(mapStateToProps, mapDispatchToProps)(CollaboratorIndex)
