import React, { Component, PropTypes } from 'react'
import { translate } from 'react-i18next'
import DownChannelsStatus from './DownChannelsStatus'

class ChannelStatus extends Component {
  render() {
    const { channel } = this.props
    const statusInfo = channel.statusInfo

    if (!statusInfo || !statusInfo.status || ['up', 'unknown'].includes(statusInfo.status)) {
      return null
    }

    let info
    switch (statusInfo.status) {
      case 'down':
        if (statusInfo.messages && statusInfo.messages.length > 0) info = ` (${statusInfo.messages.join(', ')}) `
        break
      case 'error':
        info = ` (code ${statusInfo.code}) `
        break
    }
    return (
      <div className='channel-status'>
        <DownChannelsStatus channels={[channel]} timestamp={statusInfo.timestamp} />
        {info}
      </div>
    )
  }

  downChannelsFormatter(number, unit, suffix, date, defaultFormatter) {
    const { t } = this.props

    switch (unit) {
      case 'second':
        return t('for {{count}} second', {count: number})
      case 'minute':
        return t('for {{count}} minute', {count: number})
      case 'hour':
        return t('for {{count}} hour', {count: number})
      case 'day':
        return t('for {{count}} day', {count: number})
      case 'week':
        return t('for {{count}} week', {count: number})
      case 'month':
        return t('for {{count}} month', {count: number})
      case 'year':
        return t('for {{count}} year', {count: number})
    }
  }
}

ChannelStatus.propTypes = {
  channel: PropTypes.object,
  t: PropTypes.func
}

export default translate()(ChannelStatus)
