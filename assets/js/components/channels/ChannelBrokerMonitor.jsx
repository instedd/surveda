import React, { PropTypes, Component } from "react"
import { connect } from "react-redux"
import { withRouter } from "react-router"
import { bindActionCreators } from "redux"
import * as actions from "../../actions/channel"
import * as routes from "../../routes"
import { translate } from "react-i18next"
import { config } from "../../config"
import LineChart from "../charts/LineChart"

class channelBrokerMonitor extends Component {
  static propTypes = {
    t: PropTypes.func,
    dispatch: PropTypes.func,
    channelId: PropTypes.any.isRequired,
    router: PropTypes.object.isRequired,
    channel: PropTypes.object,
  }

  constructor(props) {
    super(props)

    this.state = {
      channelBrokerHistory: [],
    }
  }

  componentWillMount() {
    const { dispatch, channelId } = this.props

    if (channelId) {
      actions.fetchChannelBrokerHistory(channelId).then((response) => {
        this.setState({ channelBrokerHistory: response })
      })
    }
  }

  componentDidUpdate() {
    const { channel, router } = this.props
    if (channel && channel.state && channel.state != "not_ready" && channel.state != "ready") {
      router.replace(routes.channel(channel.id))
    }
  }

  onConfirmClick(capacity) {
    const { dispatch, router } = this.props
    dispatch(actions.setCapacity(capacity))
    dispatch(actions.updateChannel())
    router.push(routes.channels)
  }

  render() {
    const { channel, t } = this.props
    const { channelBrokerHistory } = this.state

    if (!channel) {
      return <div>{t("Loading...")}</div>
    }

    return (
      <div className="cockpit">
        <div className="row">
          <h3>Active Contacts</h3>
          <LineChart data={channelBrokerHistory} variable={"activeContacts"} />
          <h3>Contact Queue</h3>
          <LineChart data={channelBrokerHistory} variable={"contactsQueueIds"} />
        </div>
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    channelId: ownProps.params.channelId,
    channel: state.channel.data,
  }
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch),
  dispatch,
})

export default translate()(
  withRouter(connect(mapStateToProps, mapDispatchToProps)(channelBrokerMonitor))
)
