import React, { Component, PropTypes } from "react"
import { connect } from "react-redux"
import { bindActionCreators } from "redux"
import { Tabs, TabLink } from "../ui"
import * as routes from "../../routes"
import { translate } from "react-i18next"
import * as channelActions from "../../actions/channel"
import { config } from "../../config"
import some from "lodash/some"

class ChannelTabs extends Component {
  componentDidMount() {
    const { channelActions, channelId } = this.props
    channelActions.fetchChannelIfNeeded(channelId)
  }

  activeChannelUI(channel) {
    return some(
      config[channel.provider],
      (provider) => provider.baseUrl == channel.channelBaseUrl && provider.channel_ui
    )
  }

  render() {
    const { channel, channelId, t } = this.props

    if (!channel) {
      return <div />
    }

    const capacityTab = this.activeChannelUI(channel) ? (
      <TabLink key="settings" tabId="channel_tabs" to={routes.channelCapacity(channelId)}>
        {t("Capacity")}
      </TabLink>
    ) : null

    return (
      <Tabs id="channel_tabs">
        <TabLink key="share" tabId="channel_tabs" to={routes.channelShare(channelId)}>
          {t("Share")}
        </TabLink>
        <TabLink key="patterns" tabId="channel_tabs" to={routes.channelPatterns(channelId)}>
          {t("Patterns")}
        </TabLink>
        {capacityTab}
      </Tabs>
    )
  }
}

ChannelTabs.propTypes = {
  t: PropTypes.func,
  channelId: PropTypes.any,
  channelActions: PropTypes.object,
  channel: PropTypes.object,
}

const mapStateToProps = (state, ownProps) => ({
  channelId: ownProps.params.channelId,
  channel: state.channel.data,
})

const mapDispatchToProps = (dispatch) => ({
  channelActions: bindActionCreators(channelActions, dispatch),
})

export default translate()(connect(mapStateToProps, mapDispatchToProps)(ChannelTabs))
