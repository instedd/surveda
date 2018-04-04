// @flow
import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as routes from '../../routes'
import { orderedItems } from '../../reducers/collection'
import * as actions from '../../actions/channels'
import range from 'lodash/range'
import * as authActions from '../../actions/authorizations'
import { AddButton, EmptyPage, CardTable, UntitledIfEmpty, SortableHeader, Modal, ConfirmationModal, PagingFooter, channelFriendlyName } from '../ui'
import { Preloader } from 'react-materialize'
import { config } from '../../config'
import { translate } from 'react-i18next'

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

  nextPage() {
    this.props.actions.nextChannelsPage()
  }

  previousPage() {
    this.props.actions.previousChannelsPage()
  }

  sortBy(property) {
    this.props.actions.sortChannelsBy(property)
  }

  synchronizeChannels() {
    this.props.authActions.synchronizeChannels()
  }

  channelDisplayName(channel) {
    if (channel.settings && channel.settings.sharedBy) {
      return `${channel.name} (shared by ${channel.settings.sharedBy})`
    } else {
      return channel.name
    }
  }

  render() {
    const { t, channels, authorizations, sortBy, sortAsc, pageSize, startIndex, endIndex, totalCount, router } = this.props

    if (!channels) {
      return (
        <div>
          <CardTable title={t('Loading channels...')} highlight />
        </div>
      )
    }

    const title = `${totalCount} ${(totalCount == 1) ? t('channel') : t('channels')}`
    const footer = <PagingFooter
      {...{startIndex, endIndex, totalCount}}
      onPreviousPage={() => this.previousPage()}
      onNextPage={() => this.nextPage()} />

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

      return <ConfirmationModal
        key={`${provider}-${index}`}
        modalId={`${provider}Modal-${index}`}
        modalText={t('Do you want to delete the channels provided by {{name}}?', {name})}
        header={t('Turn off {{name}}', {name})}
        confirmationText={t('Yes')}
        onConfirm={() => this.deleteProvider(provider, index)}
        style={{maxWidth: '600px'}}
        showCancel
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

    let providerModals = []
    for (let index in config.verboice) {
      providerModals.push(providerModal('verboice', index, config.verboice[index].friendlyName, multipleVerboice))
    }
    for (let index in config.nuntium) {
      providerModals.push(providerModal('nuntium', index, config.nuntium[index].friendlyName, multipleNuntium))
    }

    const nuntiumProviderUI = (index, multiple) => {
      let name = 'Nuntium'
      const { t } = this.props
      if (multiple) name = `${name} (${config.nuntium[index].friendlyName})`

      return (
        <li key={`nuntium-${index}`} className='collection-item icon nuntium'>
          <h5>{name}</h5>
          {providerSwitch('nuntium', index)}
          <span onClick={() => window.open(config.nuntium[index].baseUrl)}>
            <i className='material-icons arrow-right'>chevron_right</i>
          </span>
          <span className='channel-description'>
            <b>{t('SMS channels')}</b>
            <br />
            {t('Clickatell, DTAC, I-POP, Multimodem iSms and 8 more')}
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
            <b>{t('Voice channels')}</b>
            <br />
            {t('Callcentric, SIP client, SIP server, Skype, Twillio')}
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
        <AddButton text={t('Add channel')} onClick={(e) => this.addChannel(e)} />
        {providerModals}

        <Modal card id='add-channel'>
          <div className='modal-content'>
            <div className='card-title header'>
              <h5>{t('Create a channel')}</h5>
              <p>{t('Surveda will sync available channels from these providers after user authorization')}</p>
            </div>
            <ul className='collection'>
              {providerUIs}
            </ul>
          </div>
        </Modal>
        { (channels.length == 0)
        ? <EmptyPage icon='assignment' title={t('You have no channels on this project')} onClick={(e) => this.addChannel(e)} createText={t('Create one', {context: 'channel'})} />
        : (
          <CardTable title={tableTitle} footer={footer} highlight className='noclick'>
            <colgroup>
              <col width='70%' />
              <col width='30%' />
            </colgroup>
            <thead>
              <tr>
                <SortableHeader text={t('Name')} property='name' sortBy={sortBy} sortAsc={sortAsc} onClick={(name) => this.sortBy(name)} />
                <SortableHeader text={t('Provider')} property='provider' sortBy={sortBy} sortAsc={sortAsc} onClick={(name) => this.sortBy(name)} />
              </tr>
            </thead>
            <tbody>
              { range(0, pageSize).map(index => {
                const channel = channels[index]

                if (!channel) return <tr key={-index} className='empty-row'><td colSpan='3' /></tr>

                return (<tr key={channel.id} onClick={() => router.push(routes.channel(channel.id))}>
                  <td>
                    <UntitledIfEmpty text={this.channelDisplayName(channel)} emptyText={t('Untitled channel')} />
                  </td>
                  <td>{`${channel.provider}${channelFriendlyName(channel)}`}</td>
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
  t: PropTypes.func,
  actions: PropTypes.object.isRequired,
  authActions: PropTypes.object.isRequired,
  channels: PropTypes.array,
  authorizations: PropTypes.object,
  sortBy: PropTypes.string,
  sortAsc: PropTypes.bool.isRequired,
  pageSize: PropTypes.number.isRequired,
  startIndex: PropTypes.number.isRequired,
  endIndex: PropTypes.number.isRequired,
  totalCount: PropTypes.number.isRequired,
  router: PropTypes.object
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
  return {
    sortBy,
    sortAsc,
    channels,
    pageSize,
    startIndex,
    endIndex,
    totalCount,
    authorizations: state.authorizations
  }
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch),
  authActions: bindActionCreators(authActions, dispatch)
})

export default translate()(withRouter(connect(mapStateToProps, mapDispatchToProps)(ChannelIndex)))
