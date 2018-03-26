import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { CardTable, AddButton, Tooltip, roleDisplayName } from '../ui'
import { Input } from 'react-materialize'
import InviteModal from '../collaborators/InviteModal'
import * as actions from '../../actions/collaborators'
import * as inviteActions from '../../actions/invites'
import * as projectActions from '../../actions/project'
import * as guestActions from '../../actions/guest'
import { translate } from 'react-i18next'

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

  levelChanged(e, collaborator) {
    const { projectId, inviteActions, actions } = this.props
    const level = e.target.value
    const action = collaborator.invited ? inviteActions.updateLevel : actions.updateLevel
    action(projectId, collaborator, level)
  }

  levelEditor(collaborator, roles, readOnly) {
    const { t } = this.props
    const roleNotPresent = !roles.includes(collaborator.role)
    const disabled = (readOnly || roleNotPresent)

    const options = roleNotPresent
        ? [collaborator.role]
        : roles

    return (
      <td className='w-select'>
        <Input type='select'
          onChange={e => this.levelChanged(e, collaborator)}
          defaultValue={collaborator.role}
          disabled={disabled}
        >
          {options.map((option) =>
            <option
              key={option}
              id={option}
              name={option}
              value={option}>
              {(collaborator.invited ? t('{{role}} (invited)', {role: roleDisplayName(option)}) : roleDisplayName(option))}
            </option>
          )}
        </Input>
      </td>
    )
  }

  remove(collaborator) {
    const { projectId, inviteActions, actions } = this.props
    const action = collaborator.invited ? inviteActions.removeInvite : actions.removeCollaborator
    action(projectId, collaborator)
  }

  availableRolesForUser() {
    const { userLevel } = this.props
    var roles = ['editor', 'reader']

    if (userLevel == 'owner' || userLevel == 'admin') {
      roles = ['admin'].concat(roles)
    }
    return roles
  }

  render() {
    const { collaborators, project, t } = this.props
    if (!collaborators) {
      return <div>{t('Loading...')}</div>
    }
    // const title = `${collaborators.length} ${(collaborators.length == 1) ? ' collaborator' : ' collaborators'}`
    const title = t('{{count}} collaborator', {count: collaborators.length})
    const roles = this.availableRolesForUser()

    const readOnly = !project || project.readOnly

    let addButton = null
    if (!readOnly) {
      addButton = (
        <AddButton text={t('Invite collaborators')} onClick={(e) => this.inviteCollaborator(e)} />
      )
    }

    const roleRemove = (c) => {
      if (!readOnly && c.role != 'owner') {
        return (<td className='action'>
          <Tooltip text={t('Remove collaborator')}>
            <a className='btn-icon-grey' onClick={() => this.remove(c)}>
              <i className='material-icons'>delete</i>
            </a>
          </Tooltip>
        </td>)
      } else {
        return (<td />)
      }
    }

    return (
      <div>
        {addButton}
        <InviteModal modalId='addCollaborator' modalText={t('The access of project collaborators will be managed through roles')} header={t('Invite collaborators')} confirmationText={t('Accept')} onConfirm={(event) => event.preventDefault()} style={{maxWidth: '800px'}} />
        <div>
          <CardTable title={title}>
            <thead>
              <tr>
                <th>{t('Email')}</th>
                <th>{t('Role')}</th>
                <th />
              </tr>
            </thead>
            <tbody>
              { collaborators.map(c => {
                return (
                  <tr key={c.email}>
                    <td> {c.email} </td>
                    {this.levelEditor(c, roles, readOnly)}
                    {roleRemove(c)}
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
  t: PropTypes.func,
  projectId: PropTypes.string.isRequired,
  project: PropTypes.object,
  collaborators: PropTypes.array,
  actions: PropTypes.object.isRequired,
  inviteActions: PropTypes.object.isRequired,
  guestActions: PropTypes.object.isRequired,
  projectActions: PropTypes.object.isRequired,
  userLevel: PropTypes.string
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
  userLevel: state.project.data ? state.project.data.level : '',
  collaborators: state.collaborators.items
})

export default translate()(connect(mapStateToProps, mapDispatchToProps)(CollaboratorIndex))
