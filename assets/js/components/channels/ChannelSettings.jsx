// @flow
import React, { Component } from "react"
import { connect } from "react-redux"
import { bindActionCreators } from "redux"
import * as routes from "../../routes"
import * as api from "../../api"
import * as channelActions from "../../actions/channel"
import ChannelUI from "./ChannelUI"
import { translate } from "react-i18next"

type Props = {
  channelId: number,
  channel: Object,
  channelActions: Object,
  router: any,
  t: Function,
}

type State = {
  accessToken?: string,
}

class ChannelSettings extends Component<Props, State> {
  constructor() {
    super()
    this.state = { accessToken: "" }
  }

  componentDidMount() {
    const { channelActions, channelId } = this.props
    channelActions.fetchChannelIfNeeded(channelId).then((channel) => this.updateChannel(channel))
  }

  componentDidUpdate(prevProps) {
    if (this.props.channel !== prevProps.channel) {
      this.updateChannel(this.props.channel)
    }
  }

  updateChannel(channel) {
    if (!channel) return

    api
      .getUIToken(channel.provider, channel.channelBaseUrl)
      .then((accessToken) => this.setState({ accessToken }))
  }

  backToChannelIndex() {
    const { router } = this.props
    router.push(routes.channels)
  }

  idForChannel(channel) {
    switch (channel.provider) {
      case "nuntium":
        return channel.settings.nuntiumChannel
      case "verboice":
        return channel.settings.verboiceChannelId
    }
  }

  paramsForChannel(channel) {
    if (channel.provider == "nuntium") {
      return { account: channel.settings.nuntiumAccount }
    }
  }

  render() {
    const { channel, t } = this.props
    const { accessToken } = this.state
    if (!channel || !accessToken) {
      return <div>{t("Loading...")}</div>
    } else {
      return (
        <div className="row white">
          <div className="col l6 offset-l3 m12">
            <ChannelUI
              baseUrl={channel.channelBaseUrl}
              accessToken={accessToken}
              channelId={this.idForChannel(channel)}
              params={this.paramsForChannel(channel)}
              onCancel={() => this.backToChannelIndex()}
              onUpdated={() => this.backToChannelIndex()}
            />
          </div>
        </div>
      )
    }
  }
}

const mapStateToProps = (state, ownProps) => ({
  channelId: parseInt(ownProps.params.channelId),
  channel: state.channel.data,
})

const mapDispatchToProps = (dispatch) => ({
  channelActions: bindActionCreators(channelActions, dispatch),
})

export default translate()(connect(mapStateToProps, mapDispatchToProps)(ChannelSettings))
