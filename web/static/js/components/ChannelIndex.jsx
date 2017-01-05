import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as actions from '../actions/channels'
import * as authActions from '../actions/authorizations'
import { AddButton, EmptyPage, CardTable } from './ui'
import { Preloader } from 'react-materialize'

class ChannelIndex extends Component {
  componentDidMount() {
    this.props.actions.fetchChannels()
    $(this.refs.popup).modal()
  }

  addChannel(event) {
    event.preventDefault()
    this.props.authActions.fetchAuthorizations()
    $(this.refs.popup).modal('open')
  }

  toggleProvider(provider) {
    this.props.authActions.toggleAuthorization(provider)
  }

  synchronizeChannels() {
    this.props.authActions.synchronizeChannels()
  }

  render() {
    const { channels, authorizations } = this.props
    const title = `${Object.keys(channels).length} ${(Object.keys(channels).length == 1) ? ' channel' : ' channels'}`

    const providerSwitch = (provider) => {
      const disabled = authorizations.fetching
      const checked = !!(authorizations.items && authorizations.items.includes(provider))
      return <div className='switch'>
        <label>
          <input type='checkbox' disabled={disabled} checked={checked} onChange={() => this.toggleProvider(provider)} />
          <span className='lever' />
        </label>
      </div>
    }

    const syncButton = do {
      if (authorizations.synchronizing) {
        <Preloader size='small' />
      } else {
        <a href='#' className='black-text' onClick={() => this.synchronizeChannels()}>
          <i className='material-icons container-rotate'>refresh</i>
        </a>
      }
    }

    const tableTitle =
      <span>
        { title }
        <span className='right'>{ syncButton }</span>
      </span>

    return (
      <div>
        <AddButton text='Add channel' onClick={(e) => this.addChannel(e)} />
        <div className='modal card' ref='popup'>
          <div className='modal-content'>
            <div className='card-title header'>
              <h5>Create a channel</h5>
              <p>Ask will sync available channels from these providers after user authorization</p>
            </div>
            <ul className='collection'>
              <li className='collection-item icon verboice'>
                <h5>Verboice</h5>
                {providerSwitch('verboice')}
                <span className='channel-description'>
                  <b>Voice channels</b>
                  <br />
                  Callcentric, SIP client, SIP server, Skype, Twillio
                </span>
                <i className='material-icons arrow-right'>chevron_right</i>
              </li>
              <li className='collection-item icon nuntium'>
                <h5>Nuntium</h5>
                {providerSwitch('nuntium')}
                <i className='material-icons arrow-right'>chevron_right</i>
                <span className='channel-description'>
                  <b>SMS channels</b>
                  <br />
                  Clickatell, DTAC, I-POP, Multimodem iSms and 8 more
                </span>
              </li>
            </ul>
          </div>
        </div>
        { (Object.keys(channels).length == 0)
        ? <EmptyPage icon='assignment' title='You have no channels on this project' onClick={(e) => this.addChannel(e)} />
        : (
          <CardTable title={tableTitle} highlight>
            <thead>
              <tr>
                <th>Name</th>
                <th>Provider</th>
              </tr>
            </thead>
            <tbody>
              { Object.keys(channels).map(id =>
                <tr key={id}>
                  <td>{channels[id].name}</td>
                  <td>{channels[id].provider}</td>
                </tr>
              )}
            </tbody>
          </CardTable>
          )
        }
      </div>
    )
  }
}

ChannelIndex.propTypes = {
  actions: PropTypes.object.isRequired,
  authActions: PropTypes.object.isRequired,
  channels: PropTypes.object,
  authorizations: PropTypes.object
}

const mapStateToProps = (state) => ({
  channels: state.channels,
  authorizations: state.authorizations
})

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch),
  authActions: bindActionCreators(authActions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(ChannelIndex)
