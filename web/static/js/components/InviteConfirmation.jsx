import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as actions from '../actions/invites'
import * as routes from '../routes'
import { UntitledIfEmpty } from './ui'
import { translate } from 'react-i18next'

class InviteConfirmation extends Component {
  componentDidMount() {
    const { dispatch, router } = this.props
    const code = this.props.location.query.code

    dispatch(actions.fetchInvite(code)).then((invite) => {
      if (invite.error) {
        router.push(routes.project(invite.project_id))
      }
    },
      (reject) => {
        if (reject.status == 404) {
          window.Materialize.toast('WARNING: Invalid invitation code', 15000)
          router.push(routes.projects)
        }
      }
    )
  }

  confirmInvitation() {
    const code = this.props.location.query.code
    const { dispatch } = this.props
    Promise.resolve(dispatch(actions.confirm(code))).then(() => {
      window.location = routes.projects
    })
  }

  render() {
    const { invite, t } = this.props

    if (!invite) {
      return <div>Loading...</div>
    }

    const inviteText = <span> {`${invite.inviter_email} has invited you to collaborate as ${invite.role} on `}<UntitledIfEmpty text={invite.project_name} emptyText={t('Untitled project')} /></span>
    const roleAction = (invite.role == 'editor' || invite.role == 'admin') ? 'manage' : 'see'
    const roleDescription = <span> { "You'll be able to " + roleAction + ' surveys, questionnaires, content and collaborators'} </span>

    return (
      <div className='row accept-invitation'>
        <div className='col s12 center'>
          <h1><i className='material-icons grey-text xxlarge'>folder_shared</i></h1>
          <p> { inviteText } </p>
          <div className='divider' />
          <p className='small-text'> { roleDescription } </p>
          <a className='btn-medium blue' onClick={() => this.confirmInvitation()}> ACCEPT INVITATION </a>
        </div>
      </div>
    )
  }
}

InviteConfirmation.propTypes = {
  t: PropTypes.func,
  location: PropTypes.object.isRequired,
  router: PropTypes.object,
  invite: PropTypes.object,
  dispatch: PropTypes.any
}

const mapStateToProps = (state, ownProps) => ({
  invite: state.invite.data,
  project: state.project.data
})

export default translate()(connect(mapStateToProps)(InviteConfirmation))
