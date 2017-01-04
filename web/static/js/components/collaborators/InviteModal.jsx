import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import { Dropdown, InputWithLabel, DropdownItem } from '../ui'
import { startCase } from 'lodash'
import * as actions from '../../actions/invites'
import * as collaboratorsActions from '../../actions/collaborators'
import * as guestActions from '../../actions/guest'
import InviteLink from './InviteLink'

export class InviteModal extends Component {
  componentDidMount() {
    $(document).ready(function() {
      $('.modal').modal()
    })
  }

  cancel() {
    this.props.guestActions.clear()
  }

  send() {
    const { projectId } = this.props
    const code = this.generateCode()
    this.props.actions.invite(projectId, code, this.state.level, this.state.email)
    this.props.collaboratorsActions.fetchCollaborators(projectId)
    this.setState({email: '', level: '', code: ''})
  }

  emailChanged(e) {
    Promise.resolve(this.props.guestActions.changeEmail(e.target.value)).then(() => {
      this.props.guestActions.generateCode()
    })
  }

  levelChanged(l) {
    Promise.resolve(this.props.guestActions.changeLevel(l)).then(() => {
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

    const cancel = <a href='#!' className=' modal-action modal-close waves-effect waves-green btn-flat' onClick={() => this.cancel()}>Cancel</a>

    const send = <a href='#!' className=' modal-action modal-close waves-effect waves-green btn-flat' onClick={() => this.send()}>Send</a>

    return (
      <div>
        <div id={modalId} className='modal' style={style}>
          <div className='modal-content'>
            <h4>{header}</h4>
            <p>{modalText}</p>
          </div>
          <InputWithLabel id='email' value={guest.email} label='email' >
            <input
              type='text'
              onChange={e => this.emailChanged(e)}
            />
          </InputWithLabel>
          <Dropdown className='step-mode underlined' label={startCase(guest.level) || 'Level'} constrainWidth={false} dataBelowOrigin={false}>
            { /* TODO: Level options should also contain reader */ }
            {['editor'].map((level) =>
              <DropdownItem key={level}>
                <a onClick={e => this.levelChanged(level)}>
                  {startCase(level)}
                </a>
              </DropdownItem>
            )}
          </Dropdown>
          {send}
          {cancel}
          { guest.code ? <InviteLink /> : <div />}
        </div>
      </div>
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
