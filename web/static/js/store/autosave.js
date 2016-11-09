export default (storeProvider, actions) => store => next => action => {
  const result = next(action)
  const state = storeProvider(store.getState())

  if (state.dirty && !state.saving) {
    return store.dispatch(actions.save())
  }

  return result
}
