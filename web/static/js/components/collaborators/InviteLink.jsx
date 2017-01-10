import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import * as actions from '../../actions/invites'
import * as collaboratorsActions from '../../actions/collaborators'
import * as guestActions from '../../actions/guest'
import CopyToClipboard from 'react-copy-to-clipboard'

export class InviteLink extends Component {
  copyLink() {
    const { projectId, guest } = this.props
    if (guest.code) {
      this.props.actions.invite(projectId, guest.code, guest.level, guest.email)
      this.props.collaboratorsActions.fetchCollaborators(projectId)
      window.Materialize.toast(`Invite link was copied to the clipboard`, 5000)
    }
  }

  inviteLink() {
    const { guest } = this.props
    return guest.code ? window.location.origin + '/confirm?code=' + guest.code : ''
  }

  render() {
    const { guest } = this.props

    if (!guest) {
      return <div>Loading...</div>
    }

    return (
      <div className='colaborate-link'>
        <i className='material-icons'>link</i>
        <span >Or invite to collaborate with a</span>
        <CopyToClipboard text={this.inviteLink()}>
          <a onClick={(() => this.copyLink())}> single use link </a>
        </CopyToClipboard>
      </div>
    )
  }
}

InviteLink.propTypes = {
  projectId: PropTypes.number,
  actions: PropTypes.object.isRequired,
  collaboratorsActions: PropTypes.object.isRequired,
  guestActions: PropTypes.object.isRequired,
  guest: PropTypes.object.isRequired
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch),
  collaboratorsActions: bindActionCreators(collaboratorsActions, dispatch),
  guestActions: bindActionCreators(guestActions, dispatch)
})

const mapStateToProps = (state) => ({
  projectId: state.project.data.id,
  guest: state.guest
})

export default connect(mapStateToProps, mapDispatchToProps)(InviteLink)
