import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { CardTable, AddButton, Tooltip } from '../ui'
import { Input } from 'react-materialize'
import InviteModal from '../collaborators/InviteModal'
import * as actions from '../../actions/collaborators'
import * as inviteActions from '../../actions/invites'
import * as projectActions from '../../actions/project'
import * as guestActions from '../../actions/guest'

class CollaboratorIndex extends Component {
  constructor(props) {
    super(props)
    this.state = {
      displayLevelEditor: false,
      currentCollaborator: null
    }
  }

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

  levelChanged(e, collaborator) {
    const { projectId, inviteActions, actions } = this.props
    this.setState({displayLevelEditor: false, currentCollaborator: null})
    const level = e.target.value
    const action = collaborator.invited ? inviteActions.updateLevel : actions.updateLevel
    action(projectId, collaborator, level)
  }

  levelEditor(collaborator) {
    const options = ['reader', 'editor']
    return (
      <Input type='select'
        onChange={e => this.levelChanged(e, collaborator)}
      >
        {options.map((option) =>
          <option
            key={option}
            id={option}
            name={option}
            value={option}>
            {option + (collaborator.invited ? ' (invited)' : '')}
          </option>
        )}
      </Input>
    )
  }

  remove(collaborator) {
    const { projectId, inviteActions, actions } = this.props
    const action = collaborator.invited ? inviteActions.removeInvite : actions.removeCollaborator
    action(projectId, collaborator)
  }

  displayLevelEditor(c) {
    this.setState({displayLevelEditor: true, currentCollaborator: c.email})
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

    const roleSelector = (c) => {
      if (!readOnly && this.state.displayLevelEditor && c.role != 'owner' && c.email == this.state.currentCollaborator) {
        return (<td>
          {this.levelEditor(c)}
        </td>)
      } else {
        return (<td onClick={() => this.displayLevelEditor(c)}>
          {c.role + (c.invited ? ' (invited)' : '') }
        </td>)
      }
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
                  <tr key={c.email}>
                    <td> {c.email} </td>
                    {roleSelector(c)}
                    <td className='action'>
                      <Tooltip text='Delete questionnaire'>
                        <a onClick={() => this.remove(c)}>
                          <i className='material-icons'>delete</i>
                        </a>
                      </Tooltip>
                    </td>
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
  inviteActions: PropTypes.object.isRequired,
  guestActions: PropTypes.object.isRequired,
  projectActions: PropTypes.object.isRequired
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch),
  inviteActions: bindActionCreators(inviteActions, dispatch),
  projectActions: bindActionCreators(projectActions, dispatch),
  guestActions: bindActionCreators(guestActions, dispatch)
})

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  project: state.project.data,
  collaborators: state.collaborators.items
})

export default connect(mapStateToProps, mapDispatchToProps)(CollaboratorIndex)
