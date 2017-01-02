// @flow
export type Survey = {
  name: string,
  cutoff: number,
  mode: string[],
  modeComparison: boolean,
  state: string,
  questionnaireIds: number[],
  questionnaireComparison: boolean,
  defaultLanguage: string,
  activeLanguage: string,
  quotaCompletedMsg: ?Prompt,
  errorMsg: ?Prompt,
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
  mode: [string[]]
};

export type Bucket = {
  condition: Condition[],
  quota: number
};

export type Condition = {
  store: string,
  value: string
};
