import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as actions from '../actions/invites'
import * as routes from '../routes'
import { defaultIfEmpty, roleDisplayName } from './ui'
import { translate } from 'react-i18next'

class InviteConfirmation extends Component {
  componentDidMount() {
    const { dispatch, router, t } = this.props
    const code = this.props.location.query.code

    dispatch(actions.fetchInvite(code)).then((invite) => {
      if (invite.error) {
        router.push(routes.project(invite.project_id))
      }
    },
      (reject) => {
        if (reject.status == 404) {
          window.Materialize.toast(t('WARNING: Invalid invitation code'), 15000)
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
      return <div>{t('Loading...')}</div>
    }

    const inviteText = t(
      '{{inviter_email}} has invited you to collaborate as {{role}} on {{project}}',
      {
        inviter_email: invite.inviter_email,
        role: roleDisplayName(invite.role),
        project: defaultIfEmpty(invite.project_name, t('Untitled project'))
      }
    )

    const roleDescription = (invite.role == 'editor' || invite.role == 'admin')
      ? t('You\'ll be able to manage surveys, questionnaires, content and collaborators')
      : t('You\'ll be able to see surveys, questionnaires, content and collaborators')

    return (
      <div className='row accept-invitation'>
        <div className='col s12 center'>
          <h1><i className='material-icons grey-text xxlarge'>folder_shared</i></h1>
          <p><span> { inviteText } </span></p>
          <div className='divider' />
          <p className='small-text'><span> { roleDescription } </span></p>
          <a className='btn-medium blue upcase' onClick={() => this.confirmInvitation()}>{t('Accept invitation')}</a>
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
