import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as actions from '../../actions/invites'
import * as collaboratorsActions from '../../actions/collaborators'
import CopyToClipboard from 'react-copy-to-clipboard'
import { translate, Trans } from 'react-i18next'

export class InviteLink extends Component {
  constructor(props) {
    super(props)
    this.copyLink = this.copyLink.bind(this)
  }
  copyLink() {
    const { projectId, guest, dispatch, t } = this.props

    if (guest.data.code) {
      dispatch(actions.invite(projectId, guest.data.code, guest.data.level, guest.data.email)).then(
        () => {
          window.Materialize.toast(t('Invite link was copied to the clipboard'), 5000)
        },
        (reject) => {
          reject.json().then(json => {
            window.Materialize.toast(t('Someone else already invited this user. Please try again'), 10000)
          })
        }
      )
      dispatch(collaboratorsActions.fetchCollaborators(projectId))
    }
  }

  inviteLink() {
    const { guest } = this.props
    if (guest.data.code) {
      return window.location.origin + '/confirm?code=' + guest.data.code
    }
    return ''
  }

  render() {
    const { guest, t } = this.props

    if (!guest) {
      return <div>{t('Loading...')}</div>
    }

    return (
      <div className='colaborate-link'>
        <i className='material-icons'>link</i>
        <CopyToClipboard text={this.inviteLink()}>
          <Trans>Or invite to collaborate with a <a onClick={this.copyLink}> single use link </a></Trans>
        </CopyToClipboard>
      </div>
    )
  }
}

InviteLink.propTypes = {
  t: PropTypes.func,
  projectId: PropTypes.number,
  guest: PropTypes.object.isRequired,
  dispatch: PropTypes.any
}

const mapStateToProps = (state) => ({
  projectId: state.project.data.id,
  guest: state.guest
})

export default translate()(connect(mapStateToProps)(InviteLink))
