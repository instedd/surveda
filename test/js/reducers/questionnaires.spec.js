// @flow
/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../web/static/js/reducers/questionnaires'
import * as actions from '../../../web/static/js/actions/questionnaires'
import { questionnaire } from '../fixtures'

describe('questionnaires reducer', () => {
  const initialState = reducer(undefined, {})

  it('should handle initial state', () => {
    expect(initialState).toEqual({fetching: false, filter: null, items: null, order: null, sortBy: null, sortAsc: true, page: {index: 0, size: 5}})
  })

  it('should start fetching questionnaires', () => {
    const projectId = 100
    const result = reducer(initialState, actions.startFetchingQuestionnaires(projectId))
    expect(result.fetching).toEqual(true)
    expect(result.filter && result.filter.projectId).toEqual(projectId)
  })

  it('should receive questionnaires', () => {
    const projectId = 100
    const questionnaires = {'1': {...questionnaire, id: 1}}
    const r1 = reducer(initialState, actions.startFetchingQuestionnaires(projectId))
    const result = reducer(r1, actions.receiveQuestionnaires(projectId, questionnaires))
    expect(result.fetching).toEqual(false)
    expect(result.items).toEqual(questionnaires)
    expect(result.filter && result.filter.projectId).toEqual(projectId)
    expect(result.order).toEqual([1])
  })

  it('should start fetching questionnaires for a different project', () => {
    const projectId = 100
    const questionnaires = {'1': {...questionnaire, id: 1}}
    const r1 = reducer(initialState, actions.startFetchingQuestionnaires(projectId))
    const r2 = reducer(r1, actions.receiveQuestionnaires(projectId, questionnaires))
    const r3 = reducer(r2, actions.startFetchingQuestionnaires(projectId + 1))
    expect(r3.items).toEqual(null)
  })

  it('should sort questionnaires by name', () => {
    const projectId = 100
    const questionnaires = {'1': {...questionnaire, id: 1, name: 'foo'}, '2': {...questionnaire, id: 2, name: 'bar'}}
    const r1 = reducer(initialState, actions.startFetchingQuestionnaires(projectId))
    const r2 = reducer(r1, actions.receiveQuestionnaires(projectId, questionnaires))
    const r3 = reducer(r2, actions.sortQuestionnairesBy('name'))
    expect(r3.order).toEqual([2, 1])
    const r4 = reducer(r3, actions.sortQuestionnairesBy('name'))
    expect(r4.order).toEqual([1, 2])
  })

  it('should go to next and previous page', () => {
    const r1 = reducer(initialState, actions.nextQuestionnairesPage())
    expect(r1.page).toEqual({index: 5, size: 5})
    const r2 = reducer(r1, actions.nextQuestionnairesPage())
    expect(r2.page).toEqual({index: 10, size: 5})
    const r3 = reducer(r2, actions.previousQuestionnairesPage())
    expect(r3.page).toEqual({index: 5, size: 5})
  })

  it('should delete questionnaire', () => {
    const projectId = 100
    const questionnaires = {'1': {...questionnaire, 'id': 1}}
    const r1 = reducer(initialState, actions.startFetchingQuestionnaires(projectId))
    const r2 = reducer(r1, actions.receiveQuestionnaires(projectId, questionnaires))
    const r3 = reducer(r2, actions.deleted(questionnaires['1']))
    expect(r3.items).toEqual({})
    expect(r3.order).toEqual([])
  })
})
