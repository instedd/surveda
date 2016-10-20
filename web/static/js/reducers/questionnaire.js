import isEqual from 'lodash/isEqual'
import * as actions from '../actions/questionnaire'

const defaultState = {
  fetching: false,
  filter: null,
  data: null
}

export default (state = defaultState, action) => {
  switch (action.type) {
    case actions.FETCH: return fetch(state, action)
    case actions.RECEIVE: return receive(state, action)
    case actions.CHANGE_NAME:
      return {
        ...state,
        data: changeName(state.data, action)
      }
  }
  return state
}

const changeName = (state, action) => {
  return {
    ...state,
    name: action.newName
  }
}

const receive = (state, action) => {
  const questionnaire = action.questionnaire
  const dataFilter = {
    projectId: questionnaire.projectId,
    questionnaireId: questionnaire.id
  }

  if (isEqual(state.filter, dataFilter)) {
    return {
      ...state,
      fetching: false,
      data: questionnaire
    }
  }

  return state
}

const fetch = (state, action) => {
  const newFilter = {
    projectId: action.projectId,
    questionnaireId: action.questionnaireId
  }

  let newData = null

  if (isEqual(state.filter, newFilter)) {
    newData = state.data
  }

  return {
    ...state,
    fetching: true,
    filter: newFilter,
    data: newData
  }
}
