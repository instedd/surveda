import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import { Modal, InputWithLabel } from '../ui'
import { Input } from 'react-materialize'
import { startCase } from 'lodash'
import * as actions from '../../actions/invites'
import * as collaboratorsActions from '../../actions/collaborators'
import * as guestActions from '../../actions/guest'
import InviteLink from './InviteLink'
import { config } from '../../config'

export class InviteModal extends Component {
  cancel() {
    this.props.guestActions.clear()
  }

  send() {
    const { projectId, guest } = this.props
    if (guest.data.code) {
      Promise.resolve(this.props.actions.inviteMail(projectId, guest.data.code, guest.data.level, guest.data.email)).then(
        () => this.props.collaboratorsActions.fetchCollaborators(projectId)
      )
      this.cancel()
      $('#addCollaborator').modal('close')
    }
  }

  emailOnChange(e) {
    this.props.guestActions.changeEmail(e.target.value)
  }

  emailOnBlur(e) {
    const { projectId, guest } = this.props
    const newEmail = e.target.value
    if (guest.errors.email) {
      return
    }
    if (newEmail != config.user) {
      Promise.resolve(this.props.guestActions.changeEmail(newEmail)).then(() => {
        Promise.resolve(this.props.actions.getInviteByEmailAndProject(projectId, guest.data.email)).then(
          (dbGuest) => {
            if (dbGuest) {
              if (!guest.data.level) {
                this.props.guestActions.changeLevel(dbGuest.level)
              }
              this.props.guestActions.setCode(dbGuest.code)
            } else {
              this.props.guestActions.generateCode()
            }
          })
      })
    } else {
      this.props.guestActions.setCode('')
    }
  }

  levelChanged(e) {
    const { guest } = this.props
    const level = e.target.value
    if (guest.data.email != config.user) {
      Promise.resolve(this.props.guestActions.changeLevel(level)).then(() => {
        this.props.guestActions.generateCode()
      })
    } else {
      this.props.guestActions.changeLevel(level)
      this.props.guestActions.setCode('')
    }
  }

  render() {
    const { header, modalText, modalId, style, guest } = this.props

    if (!guest) {
      return <div>Loading...</div>
    }

    const cancelButton = <a href='#!' className=' modal-action modal-close btn-flat grey-text' onClick={() => this.cancel()}>Cancel</a>

    const validEmail = guest.data.email && !guest.errors.email

    const sendButton = guest.data.code && validEmail
    ? <a href='#!' className=' modal-action modal-close waves-effect btn-medium blue' onClick={() => this.send()}>Send</a>
    : <a className='btn-medium disabled'>Send</a>

    const initOptions = {
      complete: () => { this.cancel() }
    }

    return (
      <Modal card id={modalId} style={style} className='invite-collaborator' initOptions={initOptions} >
        <div className='modal-content'>
          <div className='card-title header'>
            <h5>{header}</h5>
            <p>{modalText}</p>
          </div>
          <div className='card-content'>
            <div className='row'>
              <div className='col s8'>
                <div className='input-field'>
                  <InputWithLabel id='collaborator_mail' value={guest.data.email} label={`Enter collaborator's email`} >
                    <input type='text' onChange={e => { this.emailOnChange(e) }} onBlur={e => { this.emailOnBlur(e) }} />
                  </InputWithLabel>
                  {
                    guest.data.email && !validEmail
                      ? <span className='small-text-bellow text-error'>
                        Please enter a valid email
                      </span>
                      : <span />
                  }
                </div>
              </div>
              <div className='col s1' />
              <Input s={3} type='select' label='Role'
                value={guest.data.level || ''}
                onChange={e => this.levelChanged(e)}>
                <option value=''>
                Select a role
                </option>
                { ['editor', 'reader'].map((role) =>
                  <option key={role} value={role}>
                    {startCase(role)}
                  </option>
                  )}
              </Input>
            </div>
            <div className='row button-actions'>
              <div className='col s12'>
                {sendButton}
                {cancelButton}
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
