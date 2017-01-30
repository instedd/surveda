/* eslint-env mocha */
import { playActionsFromState } from '../spec_helper'
import expect from 'expect'
import reducer from '../../../web/static/js/reducers/guest'
import * as actions from '../../../web/static/js/actions/guest'

describe('guest reducer', () => {
  const initialState = reducer(undefined, {})
  const playActions = playActionsFromState(initialState, reducer)

  it('should change email', () => {
    const email = 'user@instedd.org'
    const result = playActions([actions.changeEmail(email)])
    expect(result.email).toEqual(email)
  })

  it('should change level', () => {
    const level = 'editor'
    const result = playActions([actions.changeLevel(level)])
    expect(result.level).toEqual(level)
  })

  it('should clear values', () => {
    const result = playActions([
      actions.changeEmail('user@instedd.org'),
      actions.changeLevel('editor'),
      actions.clear()
    ])
    expect(result.level).toEqual('')
    expect(result.email).toEqual('')
    expect(result.code).toEqual('')
  })

  it('does not generate code if email is not present', () => {
    const result = playActions([
      actions.changeLevel('editor'),
      actions.generateCode()
    ])
    expect(result.code).toEqual('')
  })

  it('does not generate code if level is not present', () => {
    const result = playActions([
      actions.changeEmail('user@instedd.org'),
      actions.generateCode()
    ])
    expect(result.code).toEqual('')
  })

  it('generates code if both email and level are present', () => {
    const result = playActions([
      actions.changeEmail('user@instedd.org'),
      actions.changeLevel('editor'),
      actions.generateCode()
    ])
    expect(result.code).toNotEqual('')
  })
})
