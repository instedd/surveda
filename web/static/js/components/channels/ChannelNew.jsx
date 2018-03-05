// @flow
import React, { Component } from 'react'
import { config } from '../../config'
import { withRouter } from 'react-router'
import * as routes from '../../routes'

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

    if (event.source == iframe.contentWindow) {
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
    return (
      <div className='row'>{ this.renderContent() }</div>
    )
  }

  renderContent() {
    const { state } = this.state

    switch (state) {
      case 'created':
        return <span>Done</span>

      default:
        (state: 'editing')
        const provider = this.channelProvider()
        return <iframe className='col s12' style={{border: '0px'}}
          ref='iframe' src={`${provider.baseUrl}/channels_ui/new`} />
    }
  }
}

export default withRouter(ChannelNew)
