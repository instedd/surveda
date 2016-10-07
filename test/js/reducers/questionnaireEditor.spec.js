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

  it('should generate initial editor state from questionnaire model', () => {
    const result = reducer(initialState, actions.initializeEditor(questionnaire))

    expect(result.questionnaire)
    .toEqual({
      id: questionnaire.id,
      name: questionnaire.name,
      modes: questionnaire.modes,
      projectId: questionnaire.projectId
    })
  })

  it('should initialize for the questionnaire creation use case', () => {
    const result = reducer(initialState, actions.newQuestionnaire(123)).questionnaire

    expect(result)
    .toEqual({
      id: null,
      name: '',
      modes: ['SMS'],
      projectId: 123
    })
  })

  it('should start with all steps collapsed', () => {
    expect(initialState.steps.current).toEqual(null)
  })

  it('should start with all steps collapsed when there are steps already', () => {
    const result = reducer(initialState, actions.initializeEditor(questionnaire))

    expect(result.steps.current).toEqual(null)
  })

  it('should create an array with the steps Ids', () => {
    expect(reducer(initialState, actions.initializeEditor(questionnaire)).steps.ids)
      .toEqual(['17141bea-a81c-4227-bdda-f5f69188b0e7', 'b6588daa-cd81-40b1-8cac-ff2e72a15c15'])
  })

  it('should put the steps inside the "items" hash', () => {
    const result = reducer(
      initialState,
      actions.initializeEditor(questionnaire)
    ).steps.items['17141bea-a81c-4227-bdda-f5f69188b0e7']

    expect(result.title).toEqual('Do you smoke?')
    expect(result.responses.items[0].response).toEqual('Yes')
    expect(result.responses.items[1].response).toEqual('No')
  })

  it('should update questionnaire with new name', () => {
    const result = playActions([
      actions.initializeEditor(questionnaire),
      actions.changeQuestionnaireName('Some other name')
    ]).questionnaire

    expect(result.name).toEqual('Some other name')
  })

  it('should change to a single mode', () => {
    const result = playActions([
      actions.initializeEditor(questionnaire),
      actions.changeQuestionnaireModes('IVR')
    ]).questionnaire

    expect(result.modes.length).toEqual(1)
    expect(result.modes).toEqual(['IVR'])
  })

  it('should select a step', () => {
    const result = playActions([
      actions.initializeEditor(questionnaire),
      actions.selectStep('b6588daa-cd81-40b1-8cac-ff2e72a15c15')
    ])

    expect(result.steps.current).toEqual('b6588daa-cd81-40b1-8cac-ff2e72a15c15')
  })

  it('should change to multiple modes', () => {
    const result = playActions([
      actions.initializeEditor(questionnaire),
      actions.changeQuestionnaireModes('SMS,IVR')
    ]).questionnaire

    /* Expectations on arrays must include a check for length
    because for JS 'Foo,Bar' == ['Foo', 'Bar']        -_- */
    expect(result.modes.length).toEqual(2)
    expect(result.modes).toEqual(['SMS', 'IVR'])
  })

  it('should update step title', () => {
    const preState = playActions([actions.initializeEditor(questionnaire)])
    const resultState = playActionsFromState(preState, [
      actions.selectStep('b6588daa-cd81-40b1-8cac-ff2e72a15c15'),
      actions.changeStepTitle('New title')]
    )

    expect(resultState.steps.items[resultState.steps.current].title).toEqual('New title')
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
