import expect from 'expect'
import reducer from '../../../web/static/js/reducers/questionnaireEditor'
import * as actions from '../../../web/static/js/actions/questionnaireEditor'

describe('questionnaireEditor reducer', () => {
  let initialState = {}

  beforeEach(() => {
    initialState = reducer(undefined, {})
  })

  it('should generate initial editor state from questionnaire model', () => {
    expect(reducer(initialState, actions.initializeEditor(questionnaire)).questionnaire)
      .toEqual({
        id: questionnaire.id,
        name: questionnaire.name
      })
  })

  it('should start with all steps collapsed', () => {
    expect(initialState.steps.current).toEqual(null)
  })

  it('should start with all steps collapsed when there are steps already', () => {
    expect(reducer(initialState, actions.initializeEditor(questionnaire)).steps.current).toEqual(null)
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
