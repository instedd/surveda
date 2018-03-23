// @flow
import { head, tail } from 'lodash'

const undoReducer = <T>(actions: UndoActions, dirtyPredicate: DirtyPredicate<T>, reducer: StoreReducer<T>): UndoReducer<T> => {
  return (state: ?DataStoreWithUndo<T>, action: any) => {
    if (state == undefined) {
      const initialState = reducer(state, action)
      return {
        ...initialState,
        undo: [],
        redo: []
      }
    }

    switch (action.type) {
      case actions.UNDO: return undo(state, reducer, action)
      case actions.REDO: return redo(state, reducer, action)
      default:
        const newState = reducer(state, action)
        if (dirtyPredicate(action, state, newState) && state.data && newState.data !== state.data) {
          return {
            ...newState,
            undo: [state.data, ...state.undo],
            redo: []
          }
        } else {
          return {
            ...newState,
            undo: state.undo,
            redo: state.redo
          }
        }
    }
  }
}

const undo = <T>(state: DataStoreWithUndo<T>, reducer: StoreReducer<T>, action: any): DataStoreWithUndo<T> => {
  if (state.undo.length == 0) {
    return state
  }

  const newState: DataStoreWithUndo<T> = {
    ...state,
    data: head(state.undo)
  }

  return {
    ...reducer(newState, action),
    undo: tail(state.undo),
    redo: [state.data, ...state.redo],
    dirty: true
  }
}

const redo = <T>(state: DataStoreWithUndo<T>, reducer: StoreReducer<T>, action: any): DataStoreWithUndo<T> => {
  if (state.redo.length == 0) {
    return state
  }

  const newState: DataStoreWithUndo<T> = {
    ...state,
    data: head(state.redo)
  }

  return {
    ...reducer(newState, action),
    undo: [state.data, ...state.undo],
    redo: tail(state.redo),
    dirty: true
  }
}

export default undoReducer
