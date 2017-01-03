import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import { Dropdown, InputWithLabel, DropdownItem } from '../ui'
import { startCase } from 'lodash'
import * as actions from '../../actions/invites'
import * as collaboratorsActions from '../../actions/collaborators'
import Crypto from 'crypto'

export class InviteModal extends Component {
  constructor(props) {
    super(props)
    this.state = {
      email: '',
      level: ''
    }
  }

  componentDidMount() {
    $(document).ready(function() {
      $('.modal').modal()
    })
  }

  cancel() {
    this.setState({email: '', level: '', code: ''})
  }

  send() {
    const { projectId } = this.props
    const code = this.generateCode()
    this.props.actions.invite(projectId, code, this.state.level, this.state.email)
    this.props.collaboratorsActions.fetchCollaborators(projectId)
    this.setState({email: '', level: '', code: ''})
  }

  emailChanged(e) {
    this.setState({email: e.target.value})
  }

  levelChanged(l) {
    this.setState({level: l})
  }

  generateCode() {
    let code = this.state.code
    if (!code) {
      code = Crypto.randomBytes(20).toString('hex')
      this.setState({code: code})
    }
    return code
  }

  copyLink() {
    const { projectId } = this.props
    const code = this.generateCode()
    this.props.actions.invite(projectId, code, this.state.level, this.state.email)
    this.props.collaboratorsActions.fetchCollaborators(projectId)
  }

  render() {
    const { header, modalText, modalId, style } = this.props

    if (!this.state) {
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
          <InputWithLabel id='email' value={this.state.email} label='email' >
            <input
              type='text'
              onChange={e => this.emailChanged(e)}
            />
          </InputWithLabel>
          <Dropdown className='step-mode underlined' label={startCase(this.state.level) || 'Level'} constrainWidth={false} dataBelowOrigin={false}>
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
          <div>
            Invite to collaborate with a
            <a onClick={e => this.copyLink()}>
              &nbsp; single use link
            </a>
          </div>
          { this.state.code ? <div> {'confirm?code=' + this.state.code} </div> : <div />}
        </div>
      </div>
    )
  }
}

InviteModal.propTypes = {
  actions: PropTypes.object.isRequired,
  collaboratorsActions: PropTypes.object.isRequired,
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
  collaboratorsActions: bindActionCreators(collaboratorsActions, dispatch)
})

const mapStateToProps = (state) => ({
  projectId: state.project.data.id
})

export default connect(mapStateToProps, mapDispatchToProps)(InviteModal)
