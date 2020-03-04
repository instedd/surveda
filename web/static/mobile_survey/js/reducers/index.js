// @flow
import { combineReducers } from 'redux'
import step from './step'
import config from './config'

export default combineReducers({
  step,
  config
})
