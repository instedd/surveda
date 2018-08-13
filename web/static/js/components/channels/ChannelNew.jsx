// @flow
import React, { Component } from 'react'
import { config } from '../../config'
import { withRouter, Link } from 'react-router'
import * as routes from '../../routes'
import { connect } from 'react-redux'
import * as channelActions from '../../actions/channels'
import { bindActionCreators } from 'redux'
import * as api from '../../api'
import ChannelUI from './ChannelUI'

type Props = {
  location: {
    query: {
      providerType: 'verboice' | 'nuntium',
      providerIndex: ?string
    }
  },
  router: any,
  channelActions: Object
};

class ChannelNew extends Component {
  props: Props;
  state: {
    state: 'editing' | 'created',
    accessToken?: string,
  };

  constructor() {
    super()
    this.state = { state: 'editing' }
  }

  channelProvider() {
    const { providerType, providerIndex = 0 } = this.props.location.query
    const index = parseInt(providerIndex)

    let baseUrl: string
    switch (providerType) {
      case 'verboice':
        baseUrl = config.verboice[index].baseUrl
        break

      case 'nuntium':
        baseUrl = config.nuntium[index].baseUrl
        break

      default:
        (providerType: empty)
        throw new Error(`Unknown provider type: ${providerType}`)
    }

    return { provider: providerType, baseUrl }
  }

  componentDidMount() {
    const { provider, baseUrl } = this.channelProvider()
    api.getUIToken(provider, baseUrl)
      .then(accessToken => this.setState({accessToken}))
  }

  onCreated(channel) {
    const { provider, baseUrl } = this.channelProvider()
    this.props.channelActions.createChannel(provider, baseUrl, channel)
    this.setState({ state: 'created' })
  }

  onCancel() {
    const { router } = this.props
    router.push(routes.channels)
  }

  render() {
    const { state } = this.state

    switch (state) {
      case 'created':
        return (
          <div className='valign-wrapper'>
            <div className='big-done center-align'>
              <i className='material-icons check'>check</i>
              <br /><br />
              <h5 className='green-text'>Channel ready to use</h5>
              <br /><br /><br />
              <Link to={routes.channels}>Back to channels</Link>
            </div>
          </div>
        )

      default:
        (state: 'editing')
        const { accessToken } = this.state
        if (!accessToken) {
          return null
        }

        const { baseUrl } = this.channelProvider()
        return (
          <div className='row white'>
            <div className='col l6 offset-l3 m12'>
              <ChannelUI
                baseUrl={baseUrl}
                accessToken={accessToken}
                channelId='new'
                onCreated={c => this.onCreated(c)}
                onCancel={() => this.onCancel()}
              />
            </div>
          </div>
        )
    }
  }
}

const mapDispatchToProps = (dispatch) => ({
  channelActions: bindActionCreators(channelActions, dispatch)
})

export default withRouter(connect(null, mapDispatchToProps)(ChannelNew))
