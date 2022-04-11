/* eslint-env mocha */
import { playActionsFromState } from '../spec_helper'
import expect from 'expect'
import assert from 'assert'
import reducer from '../../../assets/js/reducers/guest'
import * as actions from '../../../assets/js/actions/guest'

describe('guest reducer', () => {
  const initialState = reducer(undefined, {})
  const playActions = playActionsFromState(initialState, reducer)

  it('should change email', () => {
    const email = 'user@instedd.org'
    const result = playActions([actions.changeEmail(email)])
    expect(result.data.email).toEqual(email)
  })

  it('should change level to editor', () => {
    const level = 'editor'
    const result = playActions([actions.changeLevel(level)])
    expect(result.data.level).toEqual(level)
  })

  it('should change level to reader', () => {
    const level = 'reader'
    const result = playActions([actions.changeLevel(level)])
    expect(result.data.level).toEqual(level)
  })

  it('should not change level to invalid values', () => {
    const level = 'invalid_value'
    const result = playActions([actions.changeLevel(level)])
    expect(result.data.level).toEqual('')
  })

  it('should clear values', () => {
    const result = playActions([
      actions.changeEmail('user@instedd.org'),
      actions.changeLevel('editor'),
      actions.clear()
    ])
    expect(result.data.level).toEqual('')
    expect(result.data.email).toEqual('')
    expect(result.data.code).toEqual('')
  })

  it('does not generate code if email is not present', () => {
    const result = playActions([
      actions.changeLevel('editor'),
      actions.generateCode()
    ])
    expect(result.data.code).toEqual('')
  })

  it('does not generate code if level is not present', () => {
    const result = playActions([
      actions.changeEmail('user@instedd.org'),
      actions.generateCode()
    ])
    expect(result.data.code).toEqual('')
  })

  it('does not generates code if email is invalid', () => {
    const result = playActions([
      actions.changeEmail('invalid-email.com'),
      actions.changeLevel('editor'),
      actions.generateCode()
    ])
    expect(result.data.code).toEqual('')
  })

  it('generates code if email is valid and level is present', () => {
    const result = playActions([
      actions.changeEmail('email@instedd.org'),
      actions.changeLevel('editor'),
      actions.generateCode()
    ])
    expect(result.data.code).toNotEqual('')
  })

  it('generates an error if email is invalid: two consecutive dots', () => {
    const result = playActions([
      actions.changeEmail('invalid..email@instedd.com')
    ])
    assert(result.errors.email)
  })

  it('generates an error if email is invalid: no @ symbol', () => {
    const result = playActions([
      actions.changeEmail('email.com')
    ])
    assert(result.errors.email)
  })

  it('generates an error if email is invalid: finishes with period', () => {
    const result = playActions([
      actions.changeEmail('email@instedd.')
    ])
    assert(result.errors.email)
  })

  it('does not generate an error if email is valid', () => {
    const result = playActions([
      actions.changeEmail('valid.email@instedd.com')
    ])
    assert(!result.errors.email)
  })
})
