// @flow
import * as actions from '../actions/questionnaires'
import collectionReducer, { projectFilterProvider } from './collection'

const itemsReducer = (state: IndexedList<Questionnaire>, _): IndexedList<Questionnaire> => state

export default collectionReducer(actions, itemsReducer, projectFilterProvider)
