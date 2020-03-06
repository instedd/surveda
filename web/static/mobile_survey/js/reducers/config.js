// @flow

// This reducer handles static values for the state
// These values are set once when the React app is served
const initialState = {
  introMessage: "",
  colorStyle: {}
}

export default (state: any = initialState, action: any) => {
  switch (action.type) {
    default: return state
  }
}
