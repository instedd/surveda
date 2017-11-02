// @flow
import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { orderedItems } from '../reducers/collection'
import * as actions from '../actions/channels'
import range from 'lodash/range'
import * as authActions from '../actions/authorizations'
import { AddButton, EmptyPage, CardTable, UntitledIfEmpty, SortableHeader, Modal, ConfirmationModal } from './ui'
import { Preloader } from 'react-materialize'
import { config } from '../config'

class ChannelIndex extends Component {
  componentDidMount() {
    this.props.actions.fetchChannels()
  }

  addChannel(event) {
    event.preventDefault()
    this.props.authActions.fetchAuthorizations()
    $('#add-channel').modal('open')
  }

  toggleProvider(provider, index, checked) {
    if (checked) {
      $(`#${provider}Modal-${index}`).modal('open')
    } else {
      this.props.authActions.toggleAuthorization(provider, index)
    }
  }

  turnOffProvider(provider, index) {
    this.props.authActions.removeAuthorization(provider, index)
  }

  deleteProvider(provider, index) {
    this.props.authActions.toggleAuthorization(provider, index)
  }

  nextPage(e) {
    e.preventDefault()
    this.props.actions.nextChannelsPage()
  }

  previousPage(e) {
    e.preventDefault()
    this.props.actions.previousChannelsPage()
  }

  sortBy(property) {
    this.props.actions.sortChannelsBy(property)
  }

  synchronizeChannels() {
    this.props.authActions.synchronizeChannels()
  }

  render() {
    const { channels, authorizations, sortBy, sortAsc, pageSize, startIndex, endIndex, totalCount, hasPreviousPage, hasNextPage } = this.props

    if (!channels) {
      return (
        <div>
          <CardTable title='Loading channels...' highlight />
        </div>
      )
    }

    const title = `${totalCount} ${(totalCount == 1) ? ' channel' : ' channels'}`
    const footer = (
      <div className='card-action right-align'>
        <ul className='pagination'>
          <li><span className='grey-text'>{startIndex}-{endIndex} of {totalCount}</span></li>
          { hasPreviousPage
            ? <li><a href='#!' onClick={e => this.previousPage(e)}><i className='material-icons'>chevron_left</i></a></li>
            : <li className='disabled'><i className='material-icons'>chevron_left</i></li>
          }
          { hasNextPage
            ? <li><a href='#!' onClick={e => this.nextPage(e)}><i className='material-icons'>chevron_right</i></a></li>
            : <li className='disabled'><i className='material-icons'>chevron_right</i></li>
          }
        </ul>
      </div>
    )

    const providerSwitch = (provider, index) => {
      const disabled = authorizations.fetching
      const checked = authActions.hasInAuthorizations(authorizations, provider, index)
      return <div className='switch'>
        <label>
          <input type='checkbox' disabled={disabled} checked={checked} onChange={() => this.toggleProvider(provider, index, checked)} />
          <span className='lever' />
        </label>
      </div>
    }

    const providerModal = (provider, index, friendlyName, multiple) => {
      let name = `${provider[0].toUpperCase()}${provider.slice(1)}`
      if (multiple) name = `${name} (${friendlyName})`

      return <ConfirmationModal key={`${provider}-${index}`} modalId={`${provider}Modal-${index}`} modalText={`Do you want to delete the channels provided by ${name}?`} header={`Turn off ${name}`} confirmationText='Yes' onConfirm={() => this.deleteProvider(provider, index)} style={{maxWidth: '600px'}} showCancel
        /* onNo={() => this.turnOffProvider(provider, index)} */
        />
    }

    let syncButton = null
    if (authorizations.synchronizing) {
      syncButton = <Preloader size='small' />
    } else {
      syncButton = <a href='#' className='black-text' onClick={() => this.synchronizeChannels()}>
        <i className='material-icons container-rotate'>refresh</i>
      </a>
    }

    const tableTitle =
      <span>
        { title }
        <span className='right'>{ syncButton }</span>
      </span>

    const multipleNuntium = config.nuntium.length > 1
    const multipleVerboice = config.verboice.length > 1

    const friendlyNamesByUrl = new Map()

    friendlyNamesByUrl.set('nuntium', (multipleNuntium ? new Map(config.nuntium.map((i) => [i.baseUrl, i.friendlyName])) : new Map()))
    friendlyNamesByUrl.set('verboice', (multipleVerboice ? new Map(config.verboice.map((i) => [i.baseUrl, i.friendlyName])) : new Map()))

    let providerModals = []
    for (let index in config.verboice) {
      providerModals.push(providerModal('verboice', index, config.verboice[index].friendlyName, multipleVerboice))
    }
    for (let index in config.nuntium) {
      providerModals.push(providerModal('nuntium', index, config.nuntium[index].friendlyName, multipleNuntium))
    }

    const nuntiumProviderUI = (index, multiple) => {
      let name = 'Nuntium'
      if (multiple) name = `${name} (${config.nuntium[index].friendlyName})`

      return (
        <li key={`nuntium-${index}`} className='collection-item icon nuntium'>
          <h5>{name}</h5>
          {providerSwitch('nuntium', index)}
          <span onClick={() => window.open(config.nuntium[index].baseUrl)}>
            <i className='material-icons arrow-right'>chevron_right</i>
          </span>
          <span className='channel-description'>
            <b>SMS channels</b>
            <br />
            Clickatell, DTAC, I-POP, Multimodem iSms and 8 more
          </span>
        </li>
      )
    }

    const verboiceProviderUI = (index, multiple) => {
      let name = 'Verboice'
      if (multiple) name = `${name} (${config.verboice[index].friendlyName})`

      return (
        <li key={`verboice-${index}`} className={`collection-item icon verboice`}>
          <h5>{name}</h5>
          {providerSwitch('verboice', index)}
          <span className='channel-description'>
            <b>Voice channels</b>
            <br />
            Callcentric, SIP client, SIP server, Skype, Twillio
          </span>
          <span onClick={() => window.open(config.verboice[index].baseUrl)}>
            <i className='material-icons arrow-right'>chevron_right</i>
          </span>
        </li>
      )
    }

    let providerUIs = []
    for (let index in config.verboice) {
      providerUIs.push(verboiceProviderUI(index, multipleVerboice))
    }
    for (let index in config.nuntium) {
      providerUIs.push(nuntiumProviderUI(index, multipleNuntium))
    }

    return (
      <div>
        <AddButton text='Add channel' onClick={(e) => this.addChannel(e)} />
        {providerModals}

        <Modal card id='add-channel'>
          <div className='modal-content'>
            <div className='card-title header'>
              <h5>Create a channel</h5>
              <p>Surveda will sync available channels from these providers after user authorization</p>
            </div>
            <ul className='collection'>
              {providerUIs}
            </ul>
          </div>
        </Modal>
        { (channels.length == 0)
        ? <EmptyPage icon='assignment' title='You have no channels on this project' onClick={(e) => this.addChannel(e)} />
        : (
          <CardTable title={tableTitle} footer={footer} highlight className='noclick'>
            <colgroup>
              <col width='70%' />
              <col width='30%' />
            </colgroup>
            <thead>
              <tr>
                <SortableHeader text='Name' property='name' sortBy={sortBy} sortAsc={sortAsc} onClick={(name) => this.sortBy(name)} />
                <SortableHeader text='Provider' property='provider' sortBy={sortBy} sortAsc={sortAsc} onClick={(name) => this.sortBy(name)} />
              </tr>
            </thead>
            <tbody>
              { range(0, pageSize).map(index => {
                const channel = channels[index]

                var friendlyName = ''
                if (channel) {
                  var friendlyNamesByProvider = friendlyNamesByUrl.get(`${channel.provider}`)

                  if (friendlyNamesByProvider) {
                    var name = friendlyNamesByProvider.get(channel.channelBaseUrl)
                    friendlyName = name ? ` (${name})` : ''
                  }
                }

                if (!channel) return <tr key={-index} className='empty-row'><td colSpan='3' /></tr>

                return (<tr key={channel.id}>
                  <td>
                    <UntitledIfEmpty text={channel.name} entityName='channel' />
                  </td>
                  <td>{`${channel.provider}${friendlyName}`}</td>
                </tr>)
              }) }
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
  channels: PropTypes.array,
  authorizations: PropTypes.object,
  sortBy: PropTypes.string,
  sortAsc: PropTypes.bool.isRequired,
  pageSize: PropTypes.number.isRequired,
  startIndex: PropTypes.number.isRequired,
  endIndex: PropTypes.number.isRequired,
  hasPreviousPage: PropTypes.bool.isRequired,
  hasNextPage: PropTypes.bool.isRequired,
  totalCount: PropTypes.number.isRequired
}

const mapStateToProps = (state) => {
  let channels = orderedItems(state.channels.items, state.channels.order)
  const sortBy = state.channels.sortBy
  const sortAsc = state.channels.sortAsc

  const totalCount = channels ? channels.length : 0
  const pageIndex = state.channels.page.index
  const pageSize = state.channels.page.size
  if (channels) {
    channels = channels.slice(pageIndex, pageIndex + pageSize)
  }
  const startIndex = Math.min(totalCount, pageIndex + 1)
  const endIndex = Math.min(pageIndex + pageSize, totalCount)
  const hasPreviousPage = startIndex > 1
  const hasNextPage = endIndex < totalCount
  return {
    sortBy,
    sortAsc,
    channels,
    pageSize,
    startIndex,
    endIndex,
    hasPreviousPage,
    hasNextPage,
    totalCount,
    authorizations: state.authorizations
  }
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch),
  authActions: bindActionCreators(authActions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(ChannelIndex)
