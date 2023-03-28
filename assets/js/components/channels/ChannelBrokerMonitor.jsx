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
      selectedPoint: null,
    }
  }

  componentWillMount() {
    const { dispatch, channelId } = this.props

    if (channelId) {
      actions.fetchChannelBrokerHistory(channelId).then((response) => {
        this.setState({
          channelBrokerHistory: response,
          selectedPoint: Object.keys(response)[0],
          selectedPointKey: 0,
        })
      })
    }
  }

  render() {
    const { channel, t } = this.props
    const { channelBrokerHistory, selectedPoint, selectedPointKey } = this.state

    if (!channel || !channelBrokerHistory || !selectedPoint) {
      return <div>{t("Loading...")}</div>
    }

    return (
      <div className="cockpit">
        <h2>{t("Broker Monitor")}</h2>
        <p>{t("This is a live monitor of the channel broker.")}</p>

        <p>Selected point ID: {selectedPoint}</p>
        <p>
          Loaded: point IDs from {Object.keys(channelBrokerHistory)[0]} to{" "}
          {Object.keys(channelBrokerHistory)[Object.keys(channelBrokerHistory).length - 1]}
        </p>
        <p>Active Contacts: {channelBrokerHistory[selectedPoint].activeContacts.length}</p>
        <p>
          {channelBrokerHistory[selectedPoint].activeContacts
            ? channelBrokerHistory[selectedPoint].activeContacts.map((contact) => {
                return (
                  <span key={contact} className="btn-small">
                    {contact}
                  </span>
                )
              })
            : null}
        </p>
        <p>Contacts Queue: {channelBrokerHistory[selectedPoint].contactsQueueIds.length}</p>
        <p>
          {channelBrokerHistory[selectedPoint].contactsQueueIds
            ? channelBrokerHistory[selectedPoint].contactsQueueIds.map((contact) => {
                return (
                  <span key={contact} className="btn-small">
                    {contact}
                  </span>
                )
              })
            : null}
        </p>
        <p>Instruction: {channelBrokerHistory[selectedPoint].instruction}</p>
        <p>Timestamp: {channelBrokerHistory[selectedPoint].insertedAt}</p>
        <p>Parameters:</p>
        <p>
          <textarea
            readOnly
            value={JSON.stringify(channelBrokerHistory[selectedPoint].parameters)}
          ></textarea>
        </p>

        <button
          onClick={() =>
            this.setState({
              selectedPointKey: selectedPointKey - 100,
              selectedPoint: Object.keys(channelBrokerHistory)[selectedPointKey - 100],
            })
          }
        >
          {" "}
          -100{" "}
        </button>
        <button
          onClick={() =>
            this.setState({
              selectedPointKey: selectedPointKey - 10,
              selectedPoint: Object.keys(channelBrokerHistory)[selectedPointKey - 10],
            })
          }
        >
          {" "}
          -10{" "}
        </button>
        <button
          onClick={() =>
            this.setState({
              selectedPointKey: selectedPointKey - 1,
              selectedPoint: Object.keys(channelBrokerHistory)[selectedPointKey - 1],
            })
          }
        >
          {" "}
          -1{" "}
        </button>
        <button
          onClick={() =>
            this.setState({
              selectedPointKey: selectedPointKey + 1,
              selectedPoint: Object.keys(channelBrokerHistory)[selectedPointKey + 1],
            })
          }
        >
          {" "}
          +1{" "}
        </button>
        <button
          onClick={() =>
            this.setState({
              selectedPointKey: selectedPointKey + 10,
              selectedPoint: Object.keys(channelBrokerHistory)[selectedPointKey + 10],
            })
          }
        >
          {" "}
          +10
        </button>
        <button
          onClick={() =>
            this.setState({
              selectedPointKey: selectedPointKey + 100,
              selectedPoint: Object.keys(channelBrokerHistory)[selectedPointKey + 100],
            })
          }
        >
          {" "}
          +100
        </button>

        <div className="row">
          <h3>Active Contacts</h3>
          <LineChart
            data={channelBrokerHistory}
            variable={"activeContacts"}
            selectedPoint={selectedPoint}
          />
          <h3>Contact Queue</h3>
          <LineChart
            data={channelBrokerHistory}
            variable={"contactsQueueIds"}
            selectedPoint={selectedPoint}
          />
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
