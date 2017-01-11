// @flow
import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { orderedItems } from '../reducers/collection'
import * as actions from '../actions/channels'
import range from 'lodash/range'
import * as authActions from '../actions/authorizations'
import { AddButton, EmptyPage, CardTable, UntitledIfEmpty, SortableHeader, Modal } from './ui'
import { Preloader } from 'react-materialize'

class ChannelIndex extends Component {
  componentDidMount() {
    this.props.actions.fetchChannels()
  }

  addChannel(event) {
    event.preventDefault()
    this.props.authActions.fetchAuthorizations()
    $('#add-channel').modal('open')
  }

  toggleProvider(provider) {
    this.props.authActions.toggleAuthorization(provider)
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

    return (
      <div>
        <AddButton text='Add channel' onClick={(e) => this.addChannel(e)} />
        <Modal card id='add-channel'>
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
        </Modal>
        { (channels.length == 0)
        ? <EmptyPage icon='assignment' title='You have no channels on this project' onClick={(e) => this.addChannel(e)} />
        : (
          <CardTable title={tableTitle} footer={footer} highlight>
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
                if (!channel) return <tr key={-index} className='empty-row'><td colSpan='3' /></tr>

                return (<tr key={channel.id}>
                  <td>
                    <UntitledIfEmpty text={channel.name} entityName='channel' />
                  </td>
                  <td>{channel.provider}</td>
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
