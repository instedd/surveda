import React, { PropTypes } from "react"
import { connect } from "react-redux"
import { translate } from "react-i18next"
import { ActionButton } from "../ui"

const ChannelPause = ({ channel, t }) => {
  if (!channel) return null
  const { statusInfo } = channel
  const isPaused = statusInfo != null && statusInfo.status == "paused"
  const text = isPaused ? t("Unpause channel") : t("Pause channel")
  const iconName = isPaused ? "play_arrow" : "pause"

  return ActionButton({ text, onClick: (e) => null, iconName })
}

ChannelPause.propTypes = {
  t: PropTypes.func,
  channel: PropTypes.object,
}

const mapStateToProps = (state, ownProps) => ({
  channel: state.channel.data,
})

export default translate()(connect(mapStateToProps)(ChannelPause))
