// @flow

export type UndoStore<T> = {
  undo: T[],
  redo: T[]
};

export type DataStoreWithUndo<T> = DataStore<T> & UndoStore<T>;

export type UndoReducer<T> = (state: ?DataStoreWithUndo<T>, action: any) => DataStoreWithUndo<T>;

export type UndoActions = {
  UNDO: string,
  REDO: string
};
