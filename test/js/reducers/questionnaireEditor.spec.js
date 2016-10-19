/* eslint-env mocha */
import expect from 'expect'
import each from 'lodash/each'
import keyBy from 'lodash/keyBy'
import reducer, { questionnaireForServer, buildNewStep } from '../../../web/static/js/reducers/questionnaireEditor'
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

    expect(result.steps)
      .toEqual({
        ids: questionnaire.steps.map(s => s.id),
        items: keyBy(questionnaire.steps, s => s.id),
        current: null
      })
  })

  // Regression test for https://github.com/instedd/ask/issues/146
  it('should start with all steps collapsed even if there is older state that suggests otherwise', () => {
    const state = playActions([
      actions.initializeEditor(questionnaire),
      actions.selectStep(questionnaire.steps[0].id),
      actions.initializeEditor(questionnaire)
    ])

    expect(state.steps.current).toEqual(null)
  })

  it('should initialize for the questionnaire creation use case', () => {
    const result = reducer(initialState, actions.newQuestionnaire(123))
    const { questionnaire, steps } = result

    expect(questionnaire)
    .toEqual({
      id: null,
      name: '',
      modes: ['SMS'],
      projectId: 123
    })

    expect(steps.ids.length).toEqual(1)

    const item = steps.items[steps.ids[0]]
    expect(item.type).toEqual('multiple-choice')
    expect(item.choices.length).toEqual(0)
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

    expect(result.steps.current.id).toEqual('b6588daa-cd81-40b1-8cac-ff2e72a15c15')
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

    expect(resultState.steps.items[resultState.steps.current.id].title).toEqual('New title')
  })

  it('should update step prompt sms', () => {
    const preState = playActions([actions.initializeEditor(questionnaire)])
    const resultState = playActionsFromState(preState, [
      actions.selectStep('b6588daa-cd81-40b1-8cac-ff2e72a15c15'),
      actions.changeStepPromptSms('New prompt')]
    )

    expect(resultState.steps.items[resultState.steps.current.id].prompt.sms).toEqual('New prompt')
  })

  it('should update step store', () => {
    const preState = playActions([actions.initializeEditor(questionnaire)])
    const resultState = playActionsFromState(preState, [
      actions.selectStep('b6588daa-cd81-40b1-8cac-ff2e72a15c15'),
      actions.changeStepStore('New store')]
    )

    expect(resultState.steps.items[resultState.steps.current.id].store).toEqual('New store')
  })

  it('should add step', () => {
    const preState = playActions([actions.initializeEditor(questionnaire)])

    const resultState = playActionsFromState(preState, [
      actions.addStep('multiple-choice')
    ])

    const newStepId = resultState.steps.ids[resultState.steps.ids.length - 1]

    expect(resultState.steps.ids.length).toEqual(preState.steps.ids.length + 1)
    expect(resultState.steps.items[newStepId].title).toEqual(buildNewStep('multiple-choice').title)
    expect(resultState.steps.current.id).toEqual(newStepId)
  })

  it('should delete step', () => {
    const preState = playActions([
      actions.initializeEditor(questionnaire),
      actions.selectStep('b6588daa-cd81-40b1-8cac-ff2e72a15c15')
    ])
    const resultState = playActionsFromState(preState, [
      actions.deleteStep()]
    )
    expect(resultState.steps.ids.length).toEqual(preState.steps.ids.length - 1)
    expect(resultState.steps.items['b6588daa-cd81-40b1-8cac-ff2e72a15c15']).toEqual(null)
    expect(resultState.steps.items['17141bea-a81c-4227-bdda-f5f69188b0e7'].title).toEqual('Do you smoke?')
    expect(resultState.steps.current).toEqual(null)
  })

  it('should add choice', () => {
    const preState = playActions([
      actions.initializeEditor(questionnaire),
      actions.selectStep('b6588daa-cd81-40b1-8cac-ff2e72a15c15')
    ])
    const resultState = playActionsFromState(preState, [
      actions.addChoice()]
    )
    expect(resultState.steps.items['b6588daa-cd81-40b1-8cac-ff2e72a15c15'].choices.length).toEqual(3)
    expect(resultState.steps.items['b6588daa-cd81-40b1-8cac-ff2e72a15c15'].choices[2].value).toEqual('Untitled option')
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

  it('should include steps in questionnaire for server', () => {
    const state = playActions([actions.initializeEditor(questionnaire)])
    const quizForServer = questionnaireForServer(state)
    expect(quizForServer.steps).toEqual(questionnaire.steps)
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
