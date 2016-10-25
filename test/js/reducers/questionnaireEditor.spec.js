/* eslint-env mocha */
describe('questionnaireEditor reducer', () => {
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
})
