// @flow
export type Channel = {
  userId?: number,
  name: string,
  type: string,
  projects: number[],
  provider: string,
  settings: {}
}
