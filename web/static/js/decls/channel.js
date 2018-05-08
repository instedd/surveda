// @flow
export type Channel = {
  userId?: number,
  name: string,
  type: string,
  projects: Project[],
  provider: string,
  settings: {},
  patterns: Array<{input: string, output: string}>
}
