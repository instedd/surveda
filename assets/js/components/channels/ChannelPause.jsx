import React, { PropTypes } from "react"
import { bindActionCreators } from "redux"
import { connect } from "react-redux"
import { translate } from "react-i18next"
import { ActionButton } from "../ui"
import * as actions from "../../actions/channel"

const ChannelPause = ({ channel, t, actions }) => {
  if (!channel) return null
  const { statusInfo } = channel
  const paused = statusInfo != null && statusInfo.status == "paused"
  const text = paused ? t("Unpause channel") : t("Pause channel")
  const icon = paused ? "play_arrow" : "pause"
  const color = paused ? "green" : "red"

  const pauseChannel = (channel, pause) => {
    console.log(`About to ${pause ? "pause" : "unpause"} channel ${channel.id}`)
    if (pause) {
      actions.pause(channel)
    } else {
      actions.unpause(channel)
    }
  }

  return ActionButton({ text, onClick: (e) => pauseChannel(channel, !paused), icon, color })
}

ChannelPause.propTypes = {
  t: PropTypes.func,
  channel: PropTypes.object,
  actions: PropTypes.object.isRequired,
}

const mapStateToProps = (state, ownProps) => ({
  channel: state.channel.data,
})

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch),
})

export default translate()(connect(mapStateToProps, mapDispatchToProps)(ChannelPause))
