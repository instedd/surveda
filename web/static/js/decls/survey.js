// @flow
export type Survey = {
  name: string,
  cutoff: number,
  mode: [?string[]],
  modeComparison: boolean,
  state: string,
  questionnaireIds: number[],
  questionnaireComparison: boolean,
  scheduleDayOfWeek: DayOfWeek,
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

export type DayOfWeek = {
  [weekday: string]: boolean
};

export type MetaSurvey = {
  data: ?Survey,
  filter: ?Filter,
  fetching: boolean,
  dirty: boolean
}

export type Filter = {
  id: number,
  projectId: number
}

export type MetaSurveys = {
  items: Survey[]
}

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
