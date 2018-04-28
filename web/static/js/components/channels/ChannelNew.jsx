// @flow
import React, { Component } from 'react'
import { config } from '../../config'
import { withRouter, Link } from 'react-router'
import * as routes from '../../routes'
import { connect } from 'react-redux'
import * as channelActions from '../../actions/channels'
import { bindActionCreators } from 'redux'

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
    state: 'editing' | 'created'
  }
  onMessage: Function;

  constructor() {
    super()
    this.onMessage = this.onMessage.bind(this)
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
    window.addEventListener('message', this.onMessage, false)
  }

  componentWillUnmount() {
    window.removeEventListener('message', this.onMessage)
  }

  onMessage(event) {
    const { iframe } = this.refs

    if (iframe && event.source == iframe.contentWindow) {
      switch (event.data.type) {
        case 'resize':
          iframe.style.height = `${event.data.height}px`
          break

        case 'created':
          const { provider, baseUrl } = this.channelProvider()
          this.props.channelActions.createChannel(provider, baseUrl, event.data.channel)
          this.setState({ state: 'created' })
          break

        case 'cancel':
          const { router } = this.props
          router.push(routes.channels)
          break

        default:
          console.log('Unexpected message received from channels UI', event.data)
      }
    }
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
        const { baseUrl } = this.channelProvider()
        return (
          <div className='row white'>
            <div className='col l6 offset-l3 m12'>
              <iframe style={{border: '0px', width: '100%'}}
                ref='iframe' src={`${baseUrl}/channels_ui/new`} />
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
