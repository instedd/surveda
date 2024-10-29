import React, { PureComponent, PropTypes } from "react"
import TimeAgo from "react-timeago"
import { translate, Trans } from "react-i18next"
import every from "lodash/every"
import map from "lodash/map"

class DownChannelsStatus extends PureComponent {
  constructor(props) {
    super(props)
    this.bindedDownChannelsFormatter = this.downChannelsFormatter.bind(this)
  }

  render() {
    const { channels, timestamp } = this.props
    const channelNames = map(channels, (channel) => channel.name)
    const paused = every(channels, (channel) => channel.statusInfo && channel.statusInfo.status == "paused")
    const text = paused ? "paused" : "down"
    return this.downChannelsDescription(channelNames, timestamp, text)
  }

  downChannelsFormatter(number, unit, suffix, date, defaultFormatter) {
    const { t } = this.props

    switch (unit) {
      case "second":
        return t("for {{count}} second", { count: number })
      case "minute":
        return t("for {{count}} minute", { count: number })
      case "hour":
        return t("for {{count}} hour", { count: number })
      case "day":
        return t("for {{count}} day", { count: number })
      case "week":
        return t("for {{count}} week", { count: number })
      case "month":
        return t("for {{count}} month", { count: number })
      case "year":
        return t("for {{count}} year", { count: number })
    }
  }

  downChannelsDescription(channelNames, timestamp, text) {
    const names = channelNames.join(", ")
    if (channelNames.length > 1) {
      return (
        <Trans>
          Channels <em>{{ names }}</em> {{text}}{" "}
          {timestamp && <TimeAgo date={timestamp} formatter={this.bindedDownChannelsFormatter} />}
        </Trans>
      )
    } else {
      const name = channelNames[0]
      return (
        <Trans>
          Channel <em>{{ name }}</em> {{text}}{" "}
          {timestamp && <TimeAgo date={timestamp} formatter={this.bindedDownChannelsFormatter} />}
        </Trans>
      )
    }
  }
}

DownChannelsStatus.propTypes = {
  channels: PropTypes.array,
  t: PropTypes.func,
  timestamp: PropTypes.string,
}

export default translate()(DownChannelsStatus)
