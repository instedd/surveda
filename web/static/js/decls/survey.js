// @flow
export type Survey = {
  name: string,
  cutoff: number,
  mode: [string[]],
  modeComparison: boolean,
  state: string,
  questionnaireIds: number[],
  questionnaireComparison: boolean,
  scheduleDayOfWeek: {
    [weekday: string]: boolean
  },
  scheduleStartTime: string,
  scheduleEndTime: string,
  channels: number[],
  respondentsCount: number,
  quotas: {
    vars: string[],
    buckets: Bucket[]
  },
  comparisons: Comparison[]
};

export type Comparison = {
  questionnaireId: number,
  mode: string[],
  ratio: ?number
};

export type Bucket = {
  condition: Condition[],
  quota: number
};

export type Condition = {
  store: string,
  value: string
};
