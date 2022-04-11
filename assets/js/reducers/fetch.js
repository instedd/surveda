// @flow
import isEqual from "lodash/isEqual"
import toInteger from "lodash/toInteger"

const initialState = {
  fetching: false,
  dirty: false,
  filter: null,
  data: null,
  errors: [],
  errorsByPath: {},
  errorsByLang: {},
  saving: false,
}

const defaultFilterProvider = (action: FilteredAction) => ({
  projectId: toInteger(action.projectId),
  id: action.id == null ? null : toInteger(action.id),
})

const defaultDirtyPredicate = (action, oldData, newData) => true

export default (
    actions: any,
    dataReducer: Reducer<any>,
    filterProvider: ?(action: FilteredAction) => Filter,
    dirtyPredicate: ?DirtyPredicate<any>
  ) =>
  (state: ?DataStore<any>, action: any): DataStore<any> => {
    if (!filterProvider) filterProvider = defaultFilterProvider
    if (!dirtyPredicate) dirtyPredicate = defaultDirtyPredicate

    state = state || initialState
    switch (action.type) {
      case actions.FETCH:
        return fetch(state, action, filterProvider)
      case actions.RECEIVE:
        return receive(state, action, filterProvider)
      case actions.SAVING:
        return saving(state, action, filterProvider)
      case actions.SAVED:
        return saved(state, action, filterProvider, dataReducer)
      default:
        return data(state, action, dataReducer, dirtyPredicate)
    }
  }

const data = (state: DataStore<any>, action, dataReducer, dirtyPredicate): DataStore<any> => {
  const newData: any = state.data == null ? null : dataReducer(state.data, action)

  if (newData !== state.data) {
    if (dirtyPredicate(action, state.data, newData)) {
      return {
        ...state,
        dirty: true,
        data: newData,
      }
    } else {
      return {
        ...state,
        data: newData,
      }
    }
  }

  return state
}

const receive = (state, action, filterProvider) => {
  const data = action.data
  const dataFilter = filterProvider(data)

  if (isEqual(state.filter, dataFilter)) {
    return {
      ...state,
      fetching: false,
      dirty: false,
      data: data,
    }
  }

  return state
}

const fetch = (state, action, filterProvider) => {
  const newFilter = filterProvider(action)

  let newData = null

  if (isEqual(state.filter, newFilter) && !state.dirty) {
    newData = state.data
  }

  return {
    ...state,
    fetching: true,
    filter: newFilter,
    data: newData,
  }
}

const saved = (state, action, filterProvider, dataReducer) => {
  const newData = action.data == null ? state.data : dataReducer(state.data, action)
  return {
    ...state,
    saving: false,
    data: newData,
  }
}

const saving = (state, action, filterProvider) => {
  return {
    ...state,
    dirty: false,
    saving: true,
  }
}
