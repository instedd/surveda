/* eslint-env mocha */
import expect from 'expect'
import each from 'lodash/each'
import reducer from '../../../web/static/js/reducers/questionnaire'
import * as actions from '../../../web/static/js/actions/questionnaire'

describe('questionnaire reducer', () => {
  const initialState = reducer(undefined, {})

  const playActions = (actions) => {
    return playActionsFromState(initialState, actions)
  }

  const playActionsFromState = (state, actions) => {
    let resultState = state
    each(actions, (a) => {
      resultState = reducer(resultState, a)
    })
    return resultState
  }

  it('has a sane initial state', () => {
    expect(initialState.fetching).toEqual(false)
    expect(initialState.filter).toEqual(null)
    expect(initialState.data).toEqual(null)
  })

  it('receives a questionnaire', () => {
    const state = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire)
    ])
    expect(state.fetching).toEqual(false)
    expect(state.data).toEqual(questionnaire)
  })

  it('fetches a questionnaire', () => {
    const state = playActions([
      actions.fetch(1, 1)
    ])

    expect(state).toEqual({
      ...state,
      fetching: true,
      filter: {
        projectId: 1,
        questionnaireId: 1
      },
      data: null
    })
  })

  it('clears data when fetching a different questionnaire', () => {
    const state = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire),
      actions.fetch(2, 2)
    ])

    expect(state).toEqual({
      ...state,
      fetching: true,
      filter: {
        projectId: 2,
        questionnaireId: 2
      },
      data: null
    })
  })

  it('keeps old data when fetching new data for the same filter', () => {
    const state = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire),
      actions.fetch(1, 1)
    ])

    expect(state).toEqual({
      ...state,
      fetching: true,
      data: questionnaire
    })
  })

  it('ignores data received based on different filter', () => {
    const state = playActions([
      actions.fetch(2, 2),
      actions.receive(questionnaire)
    ])

    expect(state).toEqual({
      ...state,
      fetching: true,
      data: null
    })
  })
})

const questionnaire = {
  'steps': [
    {
      'type': 'multiple-choice',
      'title': 'Do you smoke?',
      'store': 'Smokes',
      'id': '17141bea-a81c-4227-bdda-f5f69188b0e7',
      'choices': [
        {
          'value': 'Yes',
          'responses': [
            'Yes',
            'Y',
            '1'
          ]
        },
        {
          'value': 'No',
          'responses': [
            'No',
            'N',
            '1'
          ]
        }
      ]
    },
    {
      'type': 'multiple-choice',
      'title': 'Do you exercise?',
      'store': 'Exercises',
      'id': 'b6588daa-cd81-40b1-8cac-ff2e72a15c15',
      'choices': [
        {
          'value': 'Yes',
          'responses': [
            'Yes',
            'Y',
            '1'
          ]
        },
        {
          'value': 'No',
          'responses': [
            'No',
            'N',
            '1'
          ]
        }
      ]
    }
  ],
  'projectId': 1,
  'name': 'Foo',
  'modes': [
    'SMS'
  ],
  'id': 1
}
