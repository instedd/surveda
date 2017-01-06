import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as actions from '../actions/invites'
import * as routes from '../routes'

class InviteConfirmation extends Component {
  componentDidMount() {
    const code = this.props.location.query.code
    this.props.actions.fetchInvite(code)
  }

  confirmInvitation() {
    const code = this.props.location.query.code
    Promise.resolve(this.props.actions.confirm(code)).then(() => {
      window.location = routes.projects
    })
  }

  render() {
    const { invite } = this.props

    if (!invite) {
      return <div>Loading...</div>
    }

    const inviteText = <div> { invite.inviter_email + ' has invited to collaborate as ' + invite.role + ' on ' + invite.project_name } </div>
    const roleAction = invite.role == 'editor' ? 'manage' : 'see'
    const roleDescription = <div> { "You'll be able to " + roleAction + ' surveys, questionnaires, content and collaborators'} </div>

    return (
      <div>
        <div> { inviteText } </div>
        <div> { roleDescription } </div>
        <a onClick={() => this.confirmInvitation()}> ACCEPT INVITATION </a>
      </div>
    )
  }
}

InviteConfirmation.propTypes = {
  location: PropTypes.object.isRequired,
  actions: PropTypes.object.isRequired,
  invite: PropTypes.object
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch)
})

const mapStateToProps = (state) => ({
  invite: state.invite.data
})

export default connect(mapStateToProps, mapDispatchToProps)(InviteConfirmation)
