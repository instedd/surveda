import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import { Modal } from '../ui'
import { Input } from 'react-materialize'
import { startCase } from 'lodash'
import * as actions from '../../actions/invites'
import * as collaboratorsActions from '../../actions/collaborators'
import * as guestActions from '../../actions/guest'
import InviteLink from './InviteLink'

export class InviteModal extends Component {
  cancel() {
    this.props.guestActions.clear()
  }

  send() {
    const { projectId, guest } = this.props
    if (guest.code) {
      this.props.actions.inviteMail(projectId, guest.code, guest.level, guest.email)
      this.props.collaboratorsActions.fetchCollaborators(projectId)
      this.cancel()
      $('#addCollaborator').modal('close')
    }
  }

  emailChanged(e) {
    Promise.resolve(this.props.guestActions.changeEmail(e.target.value)).then(() => {
      this.props.guestActions.generateCode()
    })
  }

  levelChanged(e) {
    const level = e.target.value
    Promise.resolve(this.props.guestActions.changeLevel(level)).then(() => {
      this.props.guestActions.generateCode()
    })
  }

  copyLink() {
    Promise.resolve(this.props.guestActions.generateCode()).then(() => {
      const { projectId, guest } = this.props
      if (guest.code) {
        this.props.actions.invite(projectId, guest.code, guest.level, guest.email)
        this.props.collaboratorsActions.fetchCollaborators(projectId)
      }
    })
  }

  render() {
    const { header, modalText, modalId, style, guest } = this.props

    if (!guest) {
      return <div>Loading...</div>
    }

    const cancel = <a href='#!' className=' modal-action modal-close btn-flat grey-text' onClick={() => this.cancel()}>Cancel</a>

    const send = <a href='#!' className=' modal-action modal-close waves-effect btn-medium blue' onClick={() => this.send()}>Send</a>

    return (
      <Modal card id={modalId} style={style} className='invite-collaborator'>
        <div className='modal-content'>
          <div className='card-title header'>
            <h5>{header}</h5>
            <p>{modalText}</p>
          </div>
          <div className='card-content'>
            <div className='row'>
              <div className='col s8'>
                <div className='input-field'>
                  <input id='collaborator_mail' type='text' onChange={e => { this.emailChanged(e) }} value={guest.email} />
                  <label htmlFor=''>Enter collaborator's email</label>
                </div>
              </div>
              <div className='col s1' />
              <Input s={3} type='select' label='Role'
                value={guest.level || ''}
                onChange={e => this.levelChanged(e)}>
                <option value=''>
                Select a role
                </option>
                { ['editor'].map((role) =>
                  <option key={role} value={role}>
                    {startCase(role)}
                  </option>
                  )}
              </Input>
            </div>
            <div className='row button-actions'>
              <div className='col s12'>
                { guest.code ? send : <a className='btn-medium disabled'>Send</a> }
                {cancel}
              </div>
            </div>
          </div>
        </div>
        <div className='card-action'>
          <InviteLink />
        </div>
      </Modal>
    )
  }
}

InviteModal.propTypes = {
  actions: PropTypes.object.isRequired,
  collaboratorsActions: PropTypes.object.isRequired,
  guestActions: PropTypes.object.isRequired,
  guest: PropTypes.object.isRequired,
  showLink: PropTypes.bool,
  showCancel: PropTypes.bool,
  linkText: PropTypes.string,
  header: PropTypes.string.isRequired,
  modalText: PropTypes.string.isRequired,
  confirmationText: PropTypes.string.isRequired,
  onConfirm: PropTypes.func.isRequired,
  modalId: PropTypes.string.isRequired,
  projectId: PropTypes.number,
  style: PropTypes.object
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

export default connect(mapStateToProps, mapDispatchToProps)(InviteModal)
