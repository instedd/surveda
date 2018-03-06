import * as autoSaveStatusActions from '../actions/autoSaveStatus'
import i18n from 'i18next'
import createHistory from 'history/createBrowserHistory'

export default (storeProvider, actions) => store => next => action => {
  const prevState = storeProvider(store.getState())
  const history = createHistory()
  const location = history.location

  // Prevent the user's internal navigation when the changes are not yet saved
  if ((prevState.saving || prevState.error) && action.type == '@@router/LOCATION_CHANGE' && !location.pathname.includes('edit')) {
    history.goBack()
    alert(i18n.t('Changes are still being saved. Please wait'))
    return false
  }

  const result = next(action)
  const state = storeProvider(store.getState())

  switch (action.type) {
    case actions.RECEIVE: store.dispatch(autoSaveStatusActions.receive(result.data)); break
    case autoSaveStatusActions.SAVING: return result
  }

  if (state.dirty && !state.saving) {
    performSaveWithRetry(store, actions)
    store.dispatch(autoSaveStatusActions.saving())
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
