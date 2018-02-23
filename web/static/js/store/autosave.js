import * as autoSaveStatusActions from '../actions/autoSaveStatus'

export default (storeProvider, actions) => store => next => action => {
  const result = next(action)
  const state = storeProvider(store.getState())

  switch (action.type) {
    case actions.RECEIVE: store.dispatch(autoSaveStatusActions.receive(result.data)); break
    case autoSaveStatusActions.SAVING: return result
    case autoSaveStatusActions.SAVED: return result
  }

  if (state.dirty && !state.saving) {
    store.dispatch(autoSaveStatusActions.saving())
    performSaveWithRetry(store, actions)
  }

  return result
}

function performSaveWithRetry(store, actions) {
  store.dispatch(actions.save()).then(response => {
    store.dispatch(autoSaveStatusActions.saved(response.data))
    return response
  }).catch(response => {
    if (response.status == 422) {
      return Promise.reject(response)
    } else {
      store.dispatch(autoSaveStatusActions.error())
      // Retry saving in 10 seconds
      window.setTimeout(function() {
        performSaveWithRetry(store, actions)
      },
        10000
      )
    }
  })
}
