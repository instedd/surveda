// @flow
export type Store = {
  questionnaire: DataStore<Questionnaire>,
  questionnaires: QuestionnaireList,
  survey: DataStore<Survey>,
  surveys: SurveyList,
  channels: ChannelList,
};

export type DataStore<T> = {
  filter?: ?Filter,
  fetching?: ?boolean, // TODO This shouldn't be optional
  saving?: ?boolean,
  dirty?: ?boolean,
  data: ?T,
  errors: Errors,
  errorsByLang: { [lang: string]: Errors }
};

export type StoreReducer<T> = (state: ?DataStore<T>, action: any) => DataStore<T>;
export type DataReducer<T> = (state: T, action: any) => T;

export type Errors = {
  [path: string]: string[]
}

export type Filter = {
  id: number,
  projectId: number,
};

export type ListStore = SurveyList | QuestionnaireList

export type BaseListStore<T> = {
  fetching: boolean,
  order: ?number,
  sortBy: ?string,
  sortAsc: boolean,
  items?: ?T[],
  page: {
    index: number,
    size: number,
  }
};

export type SurveyList = BaseListStore<Survey> & {
  projectId: ?number,
};

export type QuestionnaireList = BaseListStore<Questionnaire> & {
  projectId: ?number,
};
