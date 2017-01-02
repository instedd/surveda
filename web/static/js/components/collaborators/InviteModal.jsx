import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import { Dropdown, InputWithLabel, DropdownItem } from '../ui'
import { startCase } from 'lodash'
import * as actions from '../../actions/invites'
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

  emailChanged(e) {
    this.setState({email: e.target.value})
  }

  levelChanged(l) {
    this.setState({level: l})
  }

  generateLink() {
    const code = Crypto.randomBytes(20).toString('hex')
    const { projectId } = this.props
    console.log('Props: ', this.props)
    console.log('Actions:', this.props.actions)
    this.props.actions.invite(projectId, code, this.state.level, this.state.email)
  }

  render() {
    // const { showLink, linkText, header, modalText, confirmationText, onConfirm, modalId, style, showCancel = false } = this.props
    const { header, modalText, modalId, style } = this.props

    if (!this.state) {
      return <div>Loading...</div>
    }
    let modalLink = null
    // let cancelLink = null
    // if (showLink) {
    //   modalLink = (<a className='modal-trigger' href={`#${modalId}`}>{linkText}</a>)
    // }
    // if (showCancel) {
    //   cancelLink = <a href='#!' className=' modal-action modal-close waves-effect waves-green btn-flat'>Cancel</a>
    // }

    console.log('Props en el render: ', this.props)
    console.log('Actions en el render:', this.props.actions)

    return (
      <div>
        {modalLink}
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
            { ['editor', 'reader'].map((level) =>
              <DropdownItem key={level}>
                <a onClick={e => this.levelChanged(level)}>
                  {startCase(level)}
                </a>
              </DropdownItem>
            )}
          </Dropdown>
          <div>
            Invite to collaborate with a
            <a onClick={e => this.generateLink()}>
              &nbsp; single use link
            </a>
          </div>
        </div>
      </div>
    )
  }
}

InviteModal.propTypes = {
  actions: PropTypes.object.isRequired,
  showLink: PropTypes.bool,
  showCancel: PropTypes.bool,
  linkText: PropTypes.string,
  header: PropTypes.string.isRequired,
  modalText: PropTypes.string.isRequired,
  confirmationText: PropTypes.string.isRequired,
  onConfirm: PropTypes.func.isRequired,
  modalId: PropTypes.string.isRequired,
  projectId: PropTypes.string,
  style: PropTypes.object
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch)
})

export default connect(null, mapDispatchToProps)(InviteModal)
