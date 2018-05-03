// @flow
import React, { Component } from 'react'

type Props = {
  baseUrl: string,
  accessToken: string,
  channelId: number | 'new',
  onCreated?: Function,
  onCancel?: Function
};

class ChannelUI extends Component {
  props: Props;
  onMessage: Function;

  constructor() {
    super()
    this.onMessage = this.onMessage.bind(this)
  }

  onMessage(event: any) {
    const { iframe } = this.refs

    if (iframe && event.source == iframe.contentWindow) {
      switch (event.data.type) {
        case 'resize':
          iframe.style.height = `${event.data.height}px`
          break

        case 'created':
          const { onCreated } = this.props
          onCreated && onCreated(event.data.channel)
          break

        case 'cancel':
          const { onCancel } = this.props
          onCancel && onCancel()
          break

        default:
          console.log('Unexpected message received from channels UI', event.data)
      }
    }
  }

  componentDidMount() {
    window.addEventListener('message', this.onMessage, false)
  }

  componentWillUnmount() {
    window.removeEventListener('message', this.onMessage)
  }

  render() {
    const { baseUrl, accessToken, channelId } = this.props

    return (
      <iframe style={{border: '0px', width: '100%'}}
        ref='iframe' src={`${baseUrl}/channels_ui/${channelId}?access_token=${accessToken}`} />
    )
  }
}

export default ChannelUI
