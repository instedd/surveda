// @flow
export type Survey = {
  id: number,
  projectId: number,
  questionnaireIds: number[],
  channels: number[],
  name: string,
  cutoff: number,
  mode: [?string[]],
  modeComparison: boolean,
  state: string,
  questionnaireComparison: boolean,
  ivrRetryConfiguration: string,
  smsRetryConfiguration: string,
  scheduleDayOfWeek: DayOfWeek,
  scheduleStartTime: string,
  scheduleEndTime: string,
  respondentsCount: number,
  quotas: {
    vars: string[],
    buckets: Bucket[]
  },
  comparisons: Comparison[]
};

export type DayOfWeek = {
  [weekday: string]: boolean
};

export type SurveyPreview = {
  id: number,
  projectId: number,
  questionnaireIds: number[],
  channels: number[],
  name: string,
  mode: [?string[]],
  state: string,
  cutoff: number,
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

export type QuotaVar = {
  var: string,
  steps?: string
};
