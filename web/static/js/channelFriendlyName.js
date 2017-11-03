import { config } from './config'

const multipleNuntium = config.nuntium.length > 1
const multipleVerboice = config.verboice.length > 1

const friendlyNamesByUrl = new Map()

friendlyNamesByUrl.set('nuntium', (multipleNuntium ? new Map(config.nuntium.map((i) => [i.baseUrl, i.friendlyName])) : new Map()))
friendlyNamesByUrl.set('verboice', (multipleVerboice ? new Map(config.verboice.map((i) => [i.baseUrl, i.friendlyName])) : new Map()))

export function channelFriendlyName(channel) {
  if (channel) {
    var friendlyNamesByProvider = friendlyNamesByUrl.get(`${channel.provider}`)
    var friendlyName = ''

    if (friendlyNamesByProvider) {
      var name = friendlyNamesByProvider.get(channel.channelBaseUrl)
      friendlyName = name ? ` (${name})` : ''
    }
    return friendlyName
  }
}
