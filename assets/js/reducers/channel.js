// @flow
import * as actions from "../actions/channel"
import fetchReducer from "./fetch"
import toInteger from "lodash/toInteger"
import findIndex from "lodash/findIndex"
import isEqual from "lodash/isEqual"
import each from "lodash/each"
import includes from "lodash/includes"

const k = (...args: any) => args

export const dataReducer = (state: Channel, action: any): Channel => {
  switch (action.type) {
    case actions.SHARE:
      return share(state, action)
    case actions.REMOVE_SHARED_PROJECT:
      return removeSharedProject(state, action)
    case actions.CREATE_PATTERN:
      return createPattern(state)
    case actions.SET_INPUT_PATTERN:
      return setInputPattern(state, action)
    case actions.SET_OUTPUT_PATTERN:
      return setOutputPattern(state, action)
    case actions.REMOVE_PATTERN:
      return removePattern(state, action)
    case actions.SET_CAPACITY:
      return setCapacity(state, action)
    default:
      return state
  }
}

const validateReducer = (reducer: StoreReducer<Channel>): StoreReducer<Channel> => {
  return (state: ?DataStore<Channel>, action: any) => {
    const newState = { ...reducer(state, action), errorsByPath: {} }
    if (newState.data) {
      validate(newState)
    }
    return newState
  }
}

const filterProvider = (action: FilteredAction) => ({
  id: action.id == null ? null : toInteger(action.id),
})

export default validateReducer(fetchReducer(actions, dataReducer, filterProvider))

const share = (state, action) => {
  return {
    ...state,
    projects: [...state.projects, action.projectId],
  }
}

const removeSharedProject = (state, action) => {
  const projectIndex = findIndex(state.projects, (projectId) =>
    isEqual(projectId, action.projectId)
  )
  return {
    ...state,
    projects: [...state.projects.slice(0, projectIndex), ...state.projects.slice(projectIndex + 1)],
  }
}

const createPattern = (state) => {
  return {
    ...state,
    patterns: [...state.patterns, { input: "", output: "" }],
  }
}

const setInputPattern = (state, action) => {
  const previousPattern = state.patterns[action.index]
  const patterns = [
    ...state.patterns.slice(0, action.index),
    { input: action.value, output: previousPattern.output },
    ...state.patterns.slice(action.index + 1),
  ]
  return {
    ...state,
    patterns: patterns,
  }
}

const setOutputPattern = (state, action) => {
  const previousPattern = state.patterns[action.index]
  const patterns = [
    ...state.patterns.slice(0, action.index),
    { input: previousPattern.input, output: action.value },
    ...state.patterns.slice(action.index + 1),
  ]
  return {
    ...state,
    patterns: patterns,
  }
}

const removePattern = (state, action) => {
  const patterns = [...state.patterns]
  const newPatterns = [...patterns.slice(0, action.index), ...patterns.slice(action.index + 1)]
  return { ...state, patterns: newPatterns }
}

const setCapacity = (state, action) => {
  return {
    ...state,
    settings: {
      ...state.settings,
      capacity: action.value,
    }
  }
}

const validate = (state: any) => {
  each(state.data.patterns, (p, index) => {
    validatePattern(state, p, index)
  })
}

const validatePattern = (state, p, index) => {
  validateNotEmpty(state, p, index)
  validateValidCharacters(state, p, index)
  validateEqualNumberOfXs(state, p, index)
}

const validateNotEmpty = (state, p, index) => {
  const errorStr = k("Pattern must not be blank")
  if (!p.input) {
    addError(state, index, "input", errorStr)
  }
  if (!p.output) {
    addError(state, index, "output", errorStr)
  }
}

const validateEqualNumberOfXs = (state, p, index) => {
  const inputXsCount = (p.input.match(/X/g) || []).length
  const outputXsCount = (p.output.match(/X/g) || []).length
  if (inputXsCount != outputXsCount) {
    const errorStr = k("Number of X's doesn't match")
    addError(state, index, "input", errorStr)
    addError(state, index, "output", errorStr)
  }
}

const validateValidCharacters = (state, p, index) => {
  const inputIsValid = p.input.match(/^[0-9X()+-\s]*$/g)
  const outputIsValid = p.output.match(/^[0-9X()+-\s]*$/g)
  const errorStr = k("Invalid characters. Only +, -, X, (, ), digits and whitespaces are allowed")
  if (!inputIsValid) {
    addError(state, index, "input", errorStr)
  }
  if (!outputIsValid) {
    addError(state, index, "output", errorStr)
  }
}

const addError = (state, index, type, error) => {
  if (state.errorsByPath[index]) {
    if (state.errorsByPath[index][type]) {
      if (!includes(state.errorsByPath[index][type], error)) {
        state.errorsByPath[index][type].push(error)
      }
    } else {
      state.errorsByPath[index][type] = [error]
    }
  } else {
    state.errorsByPath[index] = {}
    state.errorsByPath[index][type] = [error]
  }
}
