// @flow
import React, { Component } from 'react'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import * as channelActions from '../../actions/channel'

type Props = {
  channelId: number,
  channelActions: Object
};

class ChannelSettings extends Component {
  props: Props;

  componentDidMount() {
    const { channelActions, channelId } = this.props
    channelActions.fetchChannelIfNeeded(channelId)
      .then(channel => {
        console.log(channel.a)
      })
  }

  render() {
    return <div>Settings</div>
  }
}

const mapStateToProps = (state, ownProps) => ({
  channelId: parseInt(ownProps.params.channelId)
})

const mapDispatchToProps = (dispatch) => ({
  channelActions: bindActionCreators(channelActions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(ChannelSettings)
