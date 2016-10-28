import each from 'lodash/each'

export const playActionsFromState = (state, reducer) => (actions) => {
  let resultState = state
  each(actions, (a) => {
    resultState = reducer(resultState, a)
  })
  return resultState
}
