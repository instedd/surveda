import React, { PropTypes, Component } from "react"
import { connect } from "react-redux"
import { withRouter } from "react-router"
import * as actions from "../../actions/channel"
import * as routes from "../../routes"
import { translate } from "react-i18next"

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
    return () => router.push(routes.channels)
  }

  onConfirmClick() {
    const { router, dispatch } = this.props
    return () => {
      router.push(routes.channels)
      dispatch(actions.setCapacity(200))
    }
  }

  render() {
    const { channel, t } = this.props

    if (!channel) {
      return <div>{t("Loading...")}</div>
    }

    return (
      <div className="white">
        <div className="row">
          <div className="col s12 m6 push-m3">
            <h4>{t("Limit the channel capacity")}</h4>
            <p className="flow-text">
              {t("Set the maximum parallel contacts this channel shouldn't exceded.")}
            </p>
            <input
              type="text"
              value={100}
              // onChange={(e) => this.inputPatternChange(e, e.target.value)}
              // onBlur={(e) => this.inputPatternSubmit(e, e.target.value)}
            />
          </div>
        </div>
        <div className="row">
          <div className="col s12 m6 push-m3">
            <a href="#!" className="btn blue right" onClick={this.onConfirmClick()}>
              {t("Update")}
            </a>
            <a href="#!" onClick={this.onCancelClick()} className="btn-flat right">
              {t("Cancel")}
            </a>
          </div>
        </div>
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  channelId: ownProps.params.channelId,
  channel: state.channel.data,
})

export default translate()(withRouter(connect(mapStateToProps)(ChannelCapacity)))
