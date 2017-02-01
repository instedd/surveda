// @flow
import * as actions from '../actions/surveys'
import collectionReducer, { projectFilterProvider } from './collection'

const itemsReducer = (state: IndexedList<Survey>, _): IndexedList<Survey> => state

export default collectionReducer(actions, itemsReducer, projectFilterProvider)
