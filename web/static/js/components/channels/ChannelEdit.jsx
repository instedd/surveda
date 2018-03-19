import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../../actions/channel'
import * as routes from '../../routes'
import { translate } from 'react-i18next'

class ChannelEdit extends Component {
  static propTypes = {
    t: PropTypes.func,
    dispatch: PropTypes.func,
    channelId: PropTypes.any.isRequired,
    router: PropTypes.object.isRequired,
    channel: PropTypes.object.isRequired,
    channels: PropTypes.object
  }

  componentWillMount() {
    const { dispatch, channelId } = this.props
    if (channelId) {
      dispatch(actions.fetchChannelIfNeeded(channelId))
    }
  }

  componentDidUpdate() {
    const { channel, router } = this.props
    if (channel && channel.state && channel.state != 'not_ready' && channel.state != 'ready') {
      router.replace(routes.channel(channel.id))
    }
  }

  render() {
    const { channel, t } = this.props

    if (Object.keys(channel).length == 0) {
      return <div>{t('Loading...')}</div>
    }

    return (
      <div className='white'>
        El sharing del channel
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  channelId: ownProps.params.channelId,
  channels: state.channels.items,
  channel: state.channel.data || {}
})

export default translate()(withRouter(connect(mapStateToProps)(ChannelEdit)))
