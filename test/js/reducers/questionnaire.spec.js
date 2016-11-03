/* eslint-env mocha */
import expect from 'expect'
import assert from 'assert'
import { playActionsFromState } from '../spec_helper'
import find from 'lodash/find'
import deepFreeze from '../../../web/static/vendor/js/deepFreeze'
import reducer from '../../../web/static/js/reducers/questionnaire'
import * as actions from '../../../web/static/js/actions/questionnaire'

describe('questionnaire reducer', () => {
  const initialState = reducer(undefined, {})

  const playActions = playActionsFromState(initialState, reducer)

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

  it('should fetch', () => {
    assert(!actions.shouldFetch({fetching: true, filter: {projectId: 1, questionnaireId: 1}}, 1, 1))
    assert(actions.shouldFetch({fetching: true, filter: null}, 1, 1))
    assert(actions.shouldFetch({fetching: true, filter: {projectId: 1, questionnaireId: 1}}, 2, 2))
    assert(actions.shouldFetch({fetching: false, filter: null}, 1, 1))
    assert(actions.shouldFetch({fetching: false, filter: {projectId: 1, questionnaireId: 1}}, 1, 1))
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

  it('should update questionnaire with new name', () => {
    const result = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire),
      actions.changeName('Some other name')
    ])

    expect(result.data.name).toEqual('Some other name')
  })

  it('should toggle mode', () => {
    const result = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire),
      actions.toggleMode('ivr')
    ])

    expect(result.data.modes.length).toEqual(2)
    expect(result.data.modes).toEqual(['sms', 'ivr'])
  })

  it('should toggle other mode', () => {
    const result = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire),
      actions.toggleMode('sms')
    ])

    /* Expectations on arrays must include a check for length
    because for JS 'Foo,Bar' == ['Foo', 'Bar']        -_- */
    expect(result.data.modes.length).toEqual(0)
  })

  it('should toggle modes multiple times', () => {
    const result = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire),
      actions.toggleMode('sms'),
      actions.toggleMode('ivr')
    ])

    /* Expectations on arrays must include a check for length
    because for JS 'Foo,Bar' == ['Foo', 'Bar']        -_- */
    expect(result.data.modes.length).toEqual(1)
    expect(result.data.modes).toEqual(['ivr'])
  })

  it('should add step', () => {
    const preState = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire)
    ])

    const resultState = playActionsFromState(preState, reducer)([
      actions.addStep()
    ])

    const newStep = resultState.data.steps[resultState.data.steps.length - 1]

    expect(resultState.data.steps.length).toEqual(preState.data.steps.length + 1)
    expect(newStep.type).toEqual('multiple-choice')
  })

  it('should change step type', () => {
    const preState = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire)
    ])

    const resultState = playActionsFromState(preState, reducer)([
      actions.changeStepType('17141bea-a81c-4227-bdda-f5f69188b0e7', 'numeric')
    ])

    const resultStep = find(resultState.data.steps, s => s.id === '17141bea-a81c-4227-bdda-f5f69188b0e7')

    expect(resultState.data.steps.length).toEqual(preState.data.steps.length)
    expect(resultStep.type).toEqual('numeric')
    expect(resultStep.title).toEqual('Do you smoke?')
    expect(resultStep.store).toEqual('Smokes')
    expect(resultStep.choices).toEqual([])
    expect(resultStep.prompt).toEqual({ sms: '' })
  })

  it('should initialize for the questionnaire creation use case', () => {
    const result = reducer(initialState, actions.newQuestionnaire(123))
    const questionnaire = result.data

    expect(questionnaire)
    .toEqual({
      id: null,
      name: '',
      modes: ['sms', 'ivr'],
      projectId: 123,
      steps: []
    })
  })

  it('should update step title', () => {
    const preState = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire)
    ])

    const resultState = playActionsFromState(preState, reducer)([
      actions.changeStepTitle('b6588daa-cd81-40b1-8cac-ff2e72a15c15', 'New title')
    ])

    expect(resultState.data.steps.length).toEqual(preState.data.steps.length)
    const step = find(resultState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
    expect(step.title).toEqual('New title')
  })

  it('should update step prompt sms', () => {
    const preState = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire)
    ])

    const resultState = playActionsFromState(preState, reducer)([
      actions.changeStepPromptSms('b6588daa-cd81-40b1-8cac-ff2e72a15c15', 'New prompt')]
    )

    const step = find(resultState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
    expect(step.prompt.sms).toEqual('New prompt')
  })

  it('should update step prompt ivr', () => {
    const preState = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire)
    ])

    const resultState = playActionsFromState(preState, reducer)([
      actions.changeStepPromptIvr('b6588daa-cd81-40b1-8cac-ff2e72a15c15', {text: 'New prompt', audio: 'tts'})]
    )

    const step = find(resultState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
    expect(step.prompt.ivr).toEqual({text: 'New prompt', audio: 'tts'})
  })

  it('should update step store', () => {
    const preState = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire)
    ])

    const resultState = playActionsFromState(preState, reducer)([
      actions.changeStepStore('b6588daa-cd81-40b1-8cac-ff2e72a15c15', 'New store')]
    )

    const step = find(resultState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
    expect(step.store).toEqual('New store')
  })

  it('should delete step', () => {
    const preState = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire)
    ])

    const preSteps = preState.data.steps

    const resultState = playActionsFromState(preState, reducer)([
      actions.deleteStep('b6588daa-cd81-40b1-8cac-ff2e72a15c15')
    ])

    const steps = resultState.data.steps

    const deletedStep = find(resultState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')

    expect(steps.length).toEqual(preSteps.length - 1)
    expect(deletedStep).toEqual(null)
    expect(steps[0].title).toEqual('Do you smoke?')
  })

  it('should add choice', () => {
    const preState = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire)
    ])

    const resultState = playActionsFromState(preState, reducer)([
      actions.addChoice('b6588daa-cd81-40b1-8cac-ff2e72a15c15')]
    )

    const step = find(resultState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
    expect(step.choices.length).toEqual(3)
    expect(step.choices[2].value).toEqual('')
    expect(step.choices[2].responses).toEqual({sms: [], ivr: []})
  })

  it('should delete choice', () => {
    const preState = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire)
    ])

    const resultState = playActionsFromState(preState, reducer)([
      actions.deleteChoice('b6588daa-cd81-40b1-8cac-ff2e72a15c15', 1)]
    )

    const step = find(resultState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
    expect(step.choices.length).toEqual(1)
    expect(step.choices[0].value).toEqual('Yes')
  })

  it('should modify choice', () => {
    const preState = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire)
    ])

    const resultState = playActionsFromState(preState, reducer)([
      actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 1, 'Maybe', 'M,MB, 3', 'May', 'end')
    ])

    const step = find(resultState.data.steps, s => s.id === '17141bea-a81c-4227-bdda-f5f69188b0e7')
    expect(step.choices.length).toEqual(2)
    expect(step.choices[1]).toEqual({
      value: 'Maybe',
      responses: {
        sms: [
          'M',
          'MB',
          '3'
        ],
        ivr: [
          'May'
        ]
      },
      skipLogic: 'end'
    })
  })

  it('should autocomplete choice options when parameter is true', () => {
    const preState = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire)
    ])

    const resultState = playActionsFromState(preState, reducer)([
      actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 1, 'Maybe', 'M,MB, 3', 'May', 'end'),
      actions.addChoice('b6588daa-cd81-40b1-8cac-ff2e72a15c15'),
      actions.changeChoice('b6588daa-cd81-40b1-8cac-ff2e72a15c15', 2, 'Maybe', '', '', 'some-id', true)
    ])

    const step = find(resultState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
    expect(step.choices.length).toEqual(3)
    expect(step.choices[2]).toEqual({
      value: 'Maybe',
      responses: {
        sms: [
          'M',
          'MB',
          '3'
        ],
        ivr: [
          'May'
        ]
      },
      skipLogic: 'some-id'
    })
  })

  it('should not autocomplete choice options when not asked to', () => {
    const preState = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire)
    ])

    const resultState = playActionsFromState(preState, reducer)([
      actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 1, 'Maybe', 'M,MB, 3', 'May', 'end'),
      actions.addChoice('b6588daa-cd81-40b1-8cac-ff2e72a15c15'),
      actions.changeChoice('b6588daa-cd81-40b1-8cac-ff2e72a15c15', 2, 'Maybe', '', '', 'some-other-id', false)
    ])

    const step = find(resultState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
    expect(step.choices.length).toEqual(3)
    expect(step.choices[2]).toEqual({
      value: 'Maybe',
      responses: {
        sms: [
          ''
        ],
        ivr: [
          ''
        ]
      },
      skipLogic: 'some-other-id'
    })
  })

  it('should not autocomplete choice options when there are options already set', () => {
    const preState = playActions([
      actions.fetch(1, 1),
      actions.receive(questionnaire)
    ])

    const resultState = playActionsFromState(preState, reducer)([
      actions.changeChoice('17141bea-a81c-4227-bdda-f5f69188b0e7', 1, 'Maybe', 'M,MB, 3', 'May', 'end'),
      actions.addChoice('b6588daa-cd81-40b1-8cac-ff2e72a15c15'),
      actions.changeChoice('b6588daa-cd81-40b1-8cac-ff2e72a15c15', 2, 'Maybe', 'Perhaps', '', 'some-other-id', true)
    ])

    const step = find(resultState.data.steps, s => s.id === 'b6588daa-cd81-40b1-8cac-ff2e72a15c15')
    expect(step.choices.length).toEqual(3)
    expect(step.choices[2]).toEqual({
      value: 'Maybe',
      responses: {
        sms: [
          'Perhaps'
        ],
        ivr: [
          ''
        ]
      },
      skipLogic: 'some-other-id'
    })
  })
})

const questionnaire = deepFreeze({
  steps: [
    {
      type: 'multiple-choice',
      title: 'Do you smoke?',
      store: 'Smokes',
      id: '17141bea-a81c-4227-bdda-f5f69188b0e7',
      choices: [
        {
          value: 'Yes',
          responses: {
            sms: [
              'Yes',
              'Y',
              '1'
            ],
            ivr: [
              'Yes'
            ]
          },
          skipLogic: null
        },
        {
          value: 'No',
          responses: {
            sms: [
              'No',
              'N',
              '1'
            ],
            ivr: [
              'No'
            ]
          },
          skipLogic: 'b6588daa-cd81-40b1-8cac-ff2e72a15c15'
        }
      ],
      prompt: {
        sms: ''
      }
    },
    {
      type: 'multiple-choice',
      title: 'Do you exercise?',
      store: 'Exercises',
      id: 'b6588daa-cd81-40b1-8cac-ff2e72a15c15',
      choices: [
        {
          value: 'Yes',
          responses: {
            sms: [
              'Yes',
              'Y',
              '1'
            ],
            ivr: [
              'Yes'
            ]
          }
        },
        {
          value: 'No',
          responses: {
            sms: [
              'No',
              'N',
              '1'
            ],
            ivr: [
              'No'
            ]
          }
        }
      ],
      prompt: {
        sms: ''
      }
    }
  ],
  projectId: 1,
  name: 'Foo',
  modes: [
    'sms'
  ],
  id: 1
})
