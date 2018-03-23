// @flow
export type Channel = {
  userId?: number,
  name: string,
  type: string,
  projects: Project[],
  provider: string,
  settings: {}
}
