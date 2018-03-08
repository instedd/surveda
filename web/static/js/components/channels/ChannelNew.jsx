// @flow
import React, { Component } from 'react'
import { config } from '../../config'
import { withRouter } from 'react-router'
import * as routes from '../../routes'
import { Link } from 'react-router'

type Props = {
  location: {
    query: {
      providerType: 'verboice' | 'nuntium',
      providerIndex: ?string
    }
  },
  router: any
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

    switch (providerType) {
      case 'verboice':
        return config.verboice[providerIndex]

      case 'nuntium':
        return config.nuntium[providerIndex]

      default:
        (providerType: empty)
        throw new Error(`Unknown provider type: ${providerType}`)
    }
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
    return this.renderContent()
  }

  renderContent() {
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
        const provider = this.channelProvider()
        return (
          <div className='row white'>
            <div className='col l6 offset-l3 m12'>
              <iframe style={{border: '0px', width: '100%'}}
                ref='iframe' src={`${provider.baseUrl}/channels_ui/new`} />
            </div>
          </div>
        )
    }
  }
}

export default withRouter(ChannelNew)
