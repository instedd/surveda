/* eslint-env mocha */
import expect from 'expect'
import each from 'lodash/each'
import reducer from '../../../web/static/js/reducers/questionnaireEditor'
import * as actions from '../../../web/static/js/actions/questionnaireEditor'

describe('questionnaireEditor reducer', () => {
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

  /* TODO: figure out how to test this with the new approach
  // Regression test for https://github.com/instedd/ask/issues/146
  it('should start with all steps collapsed even if there is older state that suggests otherwise', () => {
    const state = playActions([
      actions.initializeEditor(questionnaire),
      actions.selectStep(questionnaire.steps[0].id),
      actions.initializeEditor(questionnaire)
    ])

    expect(state.steps.current).toEqual(null)
  })

  it('should start with all steps collapsed', () => {
    expect(initialState.steps.current).toEqual(null)
  })

  it('should start with all steps collapsed when there are steps already', () => {
    const result = reducer(initialState, actions.initializeEditor(questionnaire))

    expect(result.steps.current).toEqual(null)
  })

  it('should select a step', () => {
    const result = playActions([
      actions.initializeEditor(questionnaire),
      actions.selectStep('b6588daa-cd81-40b1-8cac-ff2e72a15c15')
    ])

    expect(result.steps.current.id).toEqual('b6588daa-cd81-40b1-8cac-ff2e72a15c15')
  })
  */

  it('should add choice', () => {
    const preState = playActions([
      actions.initializeEditor(questionnaire),
      actions.selectStep('b6588daa-cd81-40b1-8cac-ff2e72a15c15')
    ])
    const resultState = playActionsFromState(preState, [
      actions.addChoice()]
    )
    expect(resultState.steps.items['b6588daa-cd81-40b1-8cac-ff2e72a15c15'].choices.length).toEqual(3)
    expect(resultState.steps.items['b6588daa-cd81-40b1-8cac-ff2e72a15c15'].choices[2].value).toEqual('')
  })

  it('should delete choice', () => {
    const preState = playActions([
      actions.initializeEditor(questionnaire),
      actions.selectStep('b6588daa-cd81-40b1-8cac-ff2e72a15c15')
    ])
    const resultState = playActionsFromState(preState, [
      actions.deleteChoice(1)]
    )
    expect(resultState.steps.items['b6588daa-cd81-40b1-8cac-ff2e72a15c15'].choices.length).toEqual(1)
    expect(resultState.steps.items['b6588daa-cd81-40b1-8cac-ff2e72a15c15'].choices[0].value).toEqual('Yes')
  })

  it('should modify choice', () => {
    const preState = playActions([
      actions.initializeEditor(questionnaire),
      actions.selectStep('17141bea-a81c-4227-bdda-f5f69188b0e7')
    ])

    const state = playActionsFromState(preState, [
      actions.changeChoice(1, 'Maybe', 'M,MB, 3')
    ])

    expect(state.steps.items[state.steps.current.id].choices.length).toEqual(2)
    expect(state.steps.items[state.steps.current.id].choices[1]).toEqual({
      value: 'Maybe',
      responses: [
        'M',
        'MB',
        '3'
      ]
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
