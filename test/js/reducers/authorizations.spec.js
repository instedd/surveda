/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../web/static/js/reducers/authorizations'
import * as actions from '../../../web/static/js/actions/authorizations'

describe('authorizations reducer', () => {
  const initialState = reducer(undefined, {})

  it('has a sane initial state', () => {
    expect(initialState.fetching).toEqual(false)
    expect(initialState.items).toEqual(null)
    expect(initialState.synchronizing).toEqual(false)
  })

  it('starts fetching', () => {
    const result = reducer(initialState, actions.startFetchingAuthorizations())
    expect(result.fetching).toEqual(true)
  })

  it('receives authorizations', () => {
    const auths = [
      {provider: 'provider_a', baseUrl: 'http://foo.com'},
      {provider: 'provider_b', baseUrl: 'http://bar.com'}
    ]
    const result = reducer({fetching: true, items: null}, actions.receiveAuthorizations(auths))
    expect(result.fetching).toEqual(false)
    expect(result.items).toEqual(auths)
  })

  it('turns authorization off', () => {
    const auths = [
      {provider: 'provider_a', baseUrl: 'http://foo.com'},
      {provider: 'provider_b', baseUrl: 'http://bar.com'}
    ]
    const result = reducer({fetching: false, items: auths},
      actions.deleteAuthorization('provider_a', 'http://foo.com'))
    expect(result.items).toEqual([{provider: 'provider_b', baseUrl: 'http://bar.com'}])
  })

  it('does nothing when deleting non existing authorization', () => {
    const auths = [
      {provider: 'provider_a', baseUrl: 'http://foo.com'},
      {provider: 'provider_b', baseUrl: 'http://bar.com'}
    ]
    const result = reducer({fetching: false, items: auths}, actions.deleteAuthorization('provider_c', 'http://baz.com'))
    expect(result.items).toEqual(auths)
  })

  it('turns authorization on', () => {
    const auths = [
      {provider: 'provider_a', baseUrl: 'http://foo.com'},
      {provider: 'provider_b', baseUrl: 'http://bar.com'}
    ]
    const result = reducer({fetching: false, items: auths},
      actions.addAuthorization('provider_c', 'http://baz.com'))
    expect(result.items).toEqual([
      {provider: 'provider_a', baseUrl: 'http://foo.com'},
      {provider: 'provider_b', baseUrl: 'http://bar.com'},
      {provider: 'provider_c', baseUrl: 'http://baz.com'}
    ])
  })

  it('does nothing when adding an already existing authorization', () => {
    const auths = [
      {provider: 'provider_a', baseUrl: 'http://foo.com'},
      {provider: 'provider_b', baseUrl: 'http://bar.com'}
    ]
    const result = reducer({fetching: false, items: auths},
      actions.addAuthorization('provider_b', 'http://bar.com'))
    expect(result.items).toEqual(auths)
  })

  it('sets synchronizing flag', () => {
    const result = reducer(initialState, actions.beginSynchronization())
    expect(result.synchronizing).toEqual(true)
  })

  it('clear synchronizing flag', () => {
    const result = reducer({...initialState, synchronizing: true}, actions.endSynchronization())
    expect(result.synchronizing).toEqual(false)
  })
})
