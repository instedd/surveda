// @flow
import React, { Component } from 'react'

type Props = {
  baseUrl: string,
  accessToken: string,
  channelId: any,
  params?: ?{[key: string]: string},
  onCreated?: Function,
  onUpdated?: Function,
  onCancel?: Function
};

class ChannelUI extends Component<Props> {
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

        case 'updated':
          const { onUpdated } = this.props
          onUpdated && onUpdated()
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

  extraParams() {
    const { params } = this.props

    if (!params) return ''

    return Object.keys(params)
      .map(key => `&${key}=${encodeURIComponent(params[key])}`)
      .join()
  }

  render() {
    const { baseUrl, accessToken, channelId } = this.props

    return (
      <iframe style={{border: '0px', width: '100%'}}
        ref='iframe' src={`${baseUrl}/channels_ui/${channelId}?access_token=${accessToken}${this.extraParams()}`} />
    )
  }
}

export default ChannelUI
