import expect from 'expect'
import reducer from '../../../web/static/js/reducers/questionnaireEditor'
import * as actions from '../../../web/static/js/actions/questionnaireEditor'

describe('questionnaireEditor reducer', () => {
  let initialState = {}

  beforeEach(() => {
    initialState = reducer(undefined, {})
  })

  it('should generate initial editor state from questionnaire model', () => {
    const result = reducer(initialState, actions.initializeEditor(questionnaire))

    expect(result.questionnaire)
    .toEqual({
      id: questionnaire.id,
      name: questionnaire.name
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
