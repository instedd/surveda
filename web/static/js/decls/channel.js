// @flow
export type ChannelList = {
  items: ?Channel[],
  fetching: boolean,
  projectId: ?number,
  order: ?number,
  sortBy: ?string,
  sortAsc: boolean,
  page: {
    index: number,
    size: number
  }
}

export type Channel = {
  userId?: number,
  name: string,
  type: string,
  provider: string,
  settings: {}
}
