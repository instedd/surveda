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

export type IndexedList<T> = {
  [entityId: number | string]: T
}

export type ListStore<T> = {
  fetching: boolean,
  order: ?number,
  sortBy: ?string,
  sortAsc: boolean,
  items?: ?IndexedList<T>,
  page: {
    index: number,
    size: number,
  }
};

export type SurveyList = ListStore<Survey> & {
  projectId: ?number,
};

export type QuestionnaireList = ListStore<Questionnaire> & {
  projectId: ?number,
};

export type ChannelList = ListStore<Channel>;
