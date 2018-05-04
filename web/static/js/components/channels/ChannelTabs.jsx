import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import {Tabs, TabLink} from '../ui'
import * as routes from '../../routes'
import { translate } from 'react-i18next'

class ChannelTabs extends Component {
  render() {
    const { channelId, t } = this.props

    return (
      <Tabs id='channel_tabs'>
        <TabLink key='share' tabId='channel_tabs' to={routes.channelShare(channelId)}>{t('Share')}</TabLink>
      </Tabs>
    )
  }
}

ChannelTabs.propTypes = {
  t: PropTypes.func,
  channelId: PropTypes.any
}

const mapStateToProps = (state, ownProps) => ({
  channelId: ownProps.params.projectId
})

export default translate()(connect(mapStateToProps)(ChannelTabs))
