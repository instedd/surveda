import React, { PropTypes, Component } from "react"
import { connect } from "react-redux"
import { withRouter } from "react-router"
import { bindActionCreators } from "redux"
import * as actions from "../../actions/channel"
import * as routes from "../../routes"
import { translate } from "react-i18next"

class ChannelCapacityForm extends Component {
  static propTypes = {
    initialValue: PropTypes.number.isRequired,
    onConfirm: PropTypes.func.isRequired,
    onCancel: PropTypes.func.isRequired,
    t: PropTypes.func.isRequired,
  }

  constructor(props) {
    super(props)
    const { initialValue } = props
    this.state = {
      inputValue: initialValue
    }
  }

  onCapacityChange(e, value) {
    if (e) e.preventDefault()
    if (value > 0) {
      this.setState({ inputValue: parseInt(value) })
    }
  }

  render() {
    const { t, onConfirm, onCancel } = this.props
    const { inputValue } = this.state
    return (
      <div className="white">
        <div className="row">
          <div className="col s12 m6 push-m3">
            <h4>{t("Limit the channel capacity")}</h4>
            <p className="flow-text">
              {t("Set the maximum parallel contacts this channel shouldn't exceded.")}
            </p>
            <input
              type="number"
              min="1"
              required
              value={inputValue}
              onChange={(e) => this.onCapacityChange(e, e.target.value)}
            />
          </div>
        </div>
        <div className="row">
          <div className="col s12 m6 push-m3">
            <a href="#!" className="btn blue right" onClick={() => onConfirm(inputValue)}>
              {t("Update")}
            </a>
            <a href="#!" onClick={() => onCancel()} className="btn-flat right">
              {t("Cancel")}
            </a>
          </div>
        </div>
      </div>
    )
  }
}

class ChannelCapacity extends Component {
  static propTypes = {
    t: PropTypes.func,
    dispatch: PropTypes.func,
    channelId: PropTypes.any.isRequired,
    router: PropTypes.object.isRequired,
    channel: PropTypes.object,
  }

  componentWillMount() {
    const { dispatch, channelId } = this.props

    if (channelId) {
      dispatch(actions.fetchChannelIfNeeded(channelId))
    }
  }

  componentDidUpdate() {
    const { channel, router } = this.props
    if (channel && channel.state && channel.state != "not_ready" && channel.state != "ready") {
      router.replace(routes.channel(channel.id))
    }
  }

  onCancelClick() {
    const { router } = this.props
    router.push(routes.channels)
  }

  onConfirmClick(capacity) {
    const { dispatch, router } = this.props
    dispatch(actions.setCapacity(capacity))
    dispatch(actions.updateChannel())
    router.push(routes.channels)
  }

  render() {
    const { channel, t } = this.props

    if (!channel) {
      return <div>{t("Loading...")}</div>
    }

    return (
      <ChannelCapacityForm
        initialValue={channel.settings.capacity || 100}
        onConfirm={(capacity) => this.onConfirmClick(capacity)}
        onCancel={() => this.onCancelClick()}
        t={t}
      />
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  channelId: ownProps.params.channelId,
  channel: state.channel.data,
})

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch),
  dispatch
})

export default translate()(withRouter(connect(mapStateToProps, mapDispatchToProps)(ChannelCapacity)))
