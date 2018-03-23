// @flow
export type Store = {
  questionnaire: DataStore<Questionnaire>,
  questionnaires: QuestionnaireList,
  survey: DataStore<Survey>,
  surveys: SurveyList,
  channels: ChannelList,
  projects: ProjectList
};

export type DataStore<T> = {
  filter?: ?Filter,
  fetching?: ?boolean, // TODO This shouldn't be optional
  saving?: ?boolean,
  dirty?: ?boolean,
  data: ?T,
  errors: ValidationError[],
  errorsByPath: ErrorsByPath,
  errorsByLang: ErrorsByLang
};

export type ErrorsByPath = {[path: string]: string[]};
export type ErrorsByLang = {[lang: string]: boolean};

export type StoreReducer<T> = (state: ?DataStore<T>, action: any) => DataStore<T>;
export type Reducer<T> = (state: T, action: any) => T;

export type ValidationError = {
  path: string,
  mode: ?string,
  lang: ?string,
  message: string
}

export type Filter = {
  id?: ?number,
  projectId?: number,
  archived?: ?boolean
};

export type Action = {
  type: string
};

export type DirtyPredicate<T> = (action: Action, oldData: ?DataStore<T>, newData: ?DataStore<T>) => boolean;

export type FilteredAction = Action & Filter;

export type ReceiveDataAction = Action & {
  data: any
};

export type ReceiveItemsAction = Action & {
  items: IndexedList<any>
}

export type ReceiveFilteredItemsAction = FilteredAction & {
  items: IndexedList<any>
}

export type IndexedList<T> = {
  [entityId: number | string]: T
}

export type ListStore<T> = {
  fetching: boolean,
  filter: ?any,
  order: ?number,
  sortBy: ?string,
  sortAsc: boolean,
  items: ?IndexedList<T>,
  page: {
    index: number,
    size: number,
  }
};

export type ListFilter = {
  projectId: ?number,
}

export type ArchiveFilter = {
  archived: ?boolean
};

export type SurveyList = ListStore<Survey> & {
  filter: ?ListFilter,
};

export type QuestionnaireList = ListStore<Questionnaire> & {
  filter: ?ListFilter,
};

export type ChannelList = ListStore<Channel>;

export type ProjectList = ListStore<Project> & {
  filter: ?ArchiveFilter,
};
