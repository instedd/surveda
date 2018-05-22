// @flow
/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../web/static/js/reducers/channel'
import * as actions from '../../../web/static/js/actions/channel'
import deepFreeze from '../../../web/static/vendor/js/deepFreeze'
import { playActionsFromState } from '../spec_helper'
import { channel } from '../fixtures'

describe('channel reducer', () => {
  const initialState = deepFreeze(reducer(undefined, {}))
  const playActions = playActionsFromState(initialState, reducer)

  it('should handle initial state', () => {
    expect(initialState.fetching).toEqual(false)
    expect(initialState.dirty).toEqual(false)
    expect(initialState.data).toEqual(null)
    expect(initialState.saving).toEqual(false)
    expect(initialState.filter).toEqual(null)
    expect(initialState.errors).toEqual([])
  })

  it('fetches a channel', () => {
    const state = playActions([
      actions.fetch(1)
    ])

    expect(state).toEqual({
      ...state,
      fetching: true,
      filter: {
        id: 1
      },
      data: null
    })
  })

  it('receives a channel', () => {
    const state = playActions([
      actions.fetch(1),
      actions.receive(channel)
    ])
    expect(state.fetching).toEqual(false)
    expect(state.data).toEqual(channel)
  })

  it('creates a new pattern', () => {
    const state = playActions([
      actions.fetch(1),
      actions.receive(channel),
      actions.createPattern
    ])
    expect(state.data.patterns.length).toEqual(1)
    expect(state.data.patterns[0]).toEqual({'input': '', 'output': ''})
  })

  it("sets pattern's input", () => {
    const state = playActions([
      actions.fetch(1),
      actions.receive(channel),
      actions.createPattern,
      actions.setInputPattern(0, '111xxx')
    ])
    expect(state.data.patterns.length).toEqual(1)
    expect(state.data.patterns[0]).toEqual({'input': '111xxx', 'output': ''})
  })

  it("sets pattern's output", () => {
    const state = playActions([
      actions.fetch(1),
      actions.receive(channel),
      actions.createPattern,
      actions.setOutputPattern(0, '222xxx')
    ])
    expect(state.data.patterns.length).toEqual(1)
    expect(state.data.patterns[0]).toEqual({'input': '', 'output': '222xxx'})
  })

  it('removes pattern', () => {
    const state = playActions([
      actions.fetch(1),
      actions.receive(channel),
      actions.createPattern,
      actions.removePattern(0)
    ])
    expect(state.data.patterns).toEqual([])
  })

  describe('validations', () => {
    it("should include check that number of X's matches", () => {
      const state = playActions([
        actions.fetch(1),
        actions.receive(channel),
        actions.createPattern,
        actions.createPattern,
        actions.setInputPattern(0, 'XX'),
        actions.setOutputPattern(0, 'X'),
        actions.setInputPattern(1, 'XX'),
        actions.setOutputPattern(1, 'XX')
      ])
      expect(state.errorsByPath[0]['input']).toInclude("Number of X's doesn't match")
      expect(state.errorsByPath[0]['output']).toInclude("Number of X's doesn't match")
      expect(state.errorsByPath[1]).toNotExist()
      expect(state.errorsByPath[1]).toNotExist()
    })

    it('should allow valid characters only', () => {
      const state = playActions([
        actions.fetch(1),
        actions.receive(channel),
        actions.createPattern,
        actions.createPattern,
        actions.createPattern,
        actions.setInputPattern(0, '+-() X1234567890'),
        actions.setOutputPattern(0, 'abcdefg'),
        actions.setInputPattern(1, 'ABCDEFG'),
        actions.setOutputPattern(1, '#'),
        actions.setInputPattern(2, '*'),
        actions.setOutputPattern(2, '$%{}.,:')
      ])
      expect(state.errorsByPath[0]['input']).toExclude('Invalid characters. Only +, -, X, (, ), digits and whitespaces are allowed')
      expect(state.errorsByPath[0]['output']).toInclude('Invalid characters. Only +, -, X, (, ), digits and whitespaces are allowed')
      expect(state.errorsByPath[1]['input']).toInclude('Invalid characters. Only +, -, X, (, ), digits and whitespaces are allowed')
      expect(state.errorsByPath[1]['output']).toInclude('Invalid characters. Only +, -, X, (, ), digits and whitespaces are allowed')
      expect(state.errorsByPath[2]['input']).toInclude('Invalid characters. Only +, -, X, (, ), digits and whitespaces are allowed')
      expect(state.errorsByPath[2]['output']).toInclude('Invalid characters. Only +, -, X, (, ), digits and whitespaces are allowed')
    })

    it('validate patterns not empty', () => {
      const state = playActions([
        actions.fetch(1),
        actions.receive(channel),
        actions.createPattern
      ])
      expect(state.errorsByPath[0]['input']).toInclude('Pattern must not be blank')
      expect(state.errorsByPath[0]['output']).toInclude('Pattern must not be blank')
    })
  })
})
