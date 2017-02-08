import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as actions from '../../actions/invites'
import * as collaboratorsActions from '../../actions/collaborators'
import CopyToClipboard from 'react-copy-to-clipboard'

export class InviteLink extends Component {

  copyLink() {
    const { projectId, guest, dispatch } = this.props
    if (guest.code) {
      dispatch(actions.invite(projectId, guest.code, guest.level, guest.email)).then(
        () => {
          window.Materialize.toast(`Invite link was copied to the clipboard`, 5000)
        },
        (reject) => {
          reject.json().then(json => {
            window.Materialize.toast(`Someone else already invited this user. Please try again`, 10000)
          })
        }
      )
      dispatch(collaboratorsActions.fetchCollaborators(projectId))
    }
  }

  inviteLink() {
    const { guest } = this.props
    if (guest.code) {
      return window.location.origin + '/confirm?code=' + guest.code
    }
    return ''
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
  guest: PropTypes.object.isRequired,
  dispatch: PropTypes.any
}

const mapStateToProps = (state) => ({
  projectId: state.project.data.id,
  guest: state.guest
})

export default connect(mapStateToProps)(InviteLink)
