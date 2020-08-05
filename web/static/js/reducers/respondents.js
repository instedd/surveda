import * as actions from '../actions/respondents'

const initialState = {
  fetching: false,
  items: null,
  order: [],
  surveyId: null,
  sortBy: null,
  sortAsc: true,
  page: {
    number: 1,
    size: 5,
    totalCount: 0
  },
  filter: null,
  fields: null,
  selectedFields: []
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.FETCH_RESPONDENTS: return fetchRespondents(state, action)
    case actions.CREATE_RESPONDENT: return createOrUpdateRespondent(state, action)
    case actions.UPDATE_RESPONDENT: return createOrUpdateRespondent(state, action)
    case actions.RECEIVE_RESPONDENTS: return receiveRespondents(state, action)
    case actions.SET_RESPONDENTS_FIELD_SELECTION: return setRespondentsFieldSelection(state, action)
    default: return state
  }
}

const fetchRespondents = (state, action) => {
  const sameSurvey = state.surveyId == action.surveyId

  const items = sameSurvey ? state.items : null
  return {
    ...state,
    items,
    fetching: true,
    surveyId: action.surveyId,
    filter: action.filter,
    sortBy: sameSurvey ? action.sortBy : null,
    sortAsc: sameSurvey ? action.sortAsc : true,
    page: {
      ...state.page,
      number: action.page
    }
  }
}

const createOrUpdateRespondent = (state, action) => ({
  ...state,
  [action.id]: {
    ...action.respondent
  }
})

const receiveRespondents = (state, action) => {
  // Select every field except reponses (only the first time)
  const selectedFields = state.selectedFields.length || !action.fields
    ? state.selectedFields
    : action.fields
        .filter(field => field.type != 'response')
        .map(field => fieldUniqueKey(field.type, field.key))
  return {
    ...state,
    fetching: false,
    items: action.respondents,
    order: action.order,
    page: {
      ...state.page,
      number: action.page,
      totalCount: action.respondentsCount
    },
    fields: action.fields,
    selectedFields: selectedFields
  }
}

const setRespondentsFieldSelection = (state, action) => {
  const fieldKey = fieldUniqueKey(action.fieldType, action.fieldKey)
  const selectField = () => [...state.selectedFields, fieldKey]
  const unselectField = () => state.selectedFields.filter(key => key != fieldKey)
  const isSelected = state.selectedFields.some(key => key == fieldKey)
  const shouldSelectField = action.selected && !isSelected
  const shouldUnselectField = !action.selected && isSelected

  const selectedFields = () => {
    if (shouldSelectField) {
      return selectField()
    } else if (shouldUnselectField) {
      return unselectField()
    } else {
      return state.selectedFields
    }
  }

  return {
    ...state,
    selectedFields: selectedFields()
  }
}

export const fieldUniqueKey = (type, key) => `${type}_${key}`
