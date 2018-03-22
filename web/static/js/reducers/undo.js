// @flow
import { head, tail } from 'lodash'

const undoReducer = <T>(actions: UndoActions, reducer: StoreReducer<T>): UndoReducer<T> => {
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
      case actions.UNDO: return undo(state)
      case actions.REDO: return redo(state)
      default:
        const newState = reducer(state, action)
        if (state.data && newState.data !== state.data) {
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

const undo = <T>(state: DataStoreWithUndo<T>): DataStoreWithUndo<T> => {
  if (state.undo.length == 0) {
    return state
  }

  return {
    ...state,
    data: head(state.undo),
    undo: tail(state.undo),
    redo: [state.data, ...state.redo],
    dirty: true
  }
}

const redo = <T>(state: DataStoreWithUndo<T>): DataStoreWithUndo<T> => {
  if (state.redo.length == 0) {
    return state
  }

  return {
    ...state,
    data: head(state.redo),
    undo: [state.data, ...state.undo],
    redo: tail(state.redo),
    dirty: true
  }
}

export default undoReducer
