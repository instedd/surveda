/* eslint-env mocha */
// @flow
import expect from 'expect'
import * as characterCounter from '../../../web/static/js/characterCounter'

describe('characterCounter', () => {
  it('character count is 0 with empty string', () => {
    expect(characterCounter.characterCount('')).toEqual(0)
  })

  it('limit is 160 for GSM 03.38 character set', () => {
    const gsm0338String = 'This is a standard SMS text. Can also includes some symbols like $%^&-_[][]!?'
    expect(characterCounter.characterLimit(gsm0338String)).toEqual(160)
  })

  it('limit is 70 if at least one character is Unicode', () => {
    const unicodeString = 'It contains È with french grave accent'
    expect(characterCounter.characterLimit(unicodeString)).toEqual(70)
  })

  it('computes character count for text of length below the limit for GSM 03.38 character set', () => {
    const textLength = 50
    const text = new Array(textLength + 1).join('a')
    expect(characterCounter.characterCount(text)).toEqual(textLength)
  })

  it('computes if limit was exceeded for text of length below the limit for GSM 03.38 character set', () => {
    const textLength = 50
    const text = new Array(textLength + 1).join('a')
    expect(characterCounter.limitExceeded(text)).toEqual(false)
  })

  it('computes character count for text of length below the limit for Unicode character set', () => {
    const textLength = 50
    const text = new Array(textLength + 1).join('È')
    expect(characterCounter.characterCount(text)).toEqual(textLength)
  })

  it('computes if limit was exceeded for text of length below the limit for Unicode character set', () => {
    const textLength = 50
    const text = new Array(textLength + 1).join('È')
    expect(characterCounter.limitExceeded(text)).toEqual(false)
  })

  it('computes character count for text of length equal to the GSM 03.38 limit', () => {
    const textLength = characterCounter.characterLimit('a')
    const text = new Array(textLength + 1).join('a')
    expect(characterCounter.characterCount(text)).toEqual(textLength)
  })

  it('computes if limit was exceeded for text of length equal to the GSM 03.38 limit', () => {
    const textLength = characterCounter.characterLimit('a')
    const text = new Array(textLength + 1).join('a')
    expect(characterCounter.limitExceeded(text)).toEqual(false)
  })

  it('computes character count for text of length equal to the Unicode limit', () => {
    const textLength = characterCounter.characterLimit('È')
    const text = new Array(textLength + 1).join('È')
    expect(characterCounter.characterCount(text)).toEqual(textLength)
  })

  it('computes if limit was exceeded for text of length equal to the Unicode limit', () => {
    const textLength = characterCounter.characterLimit('È')
    const text = new Array(textLength + 1).join('È')
    expect(characterCounter.limitExceeded(text)).toEqual(false)
  })

  it('computes if limit was exceeded for text longer than the GSM 03.38 limit', () => {
    const textLength = characterCounter.characterLimit('a') + 1
    const text = new Array(textLength + 1).join('a')
    expect(characterCounter.limitExceeded(text)).toEqual(true)
  })

  it('computes if limit was exceeded for text longer than the Unicode limit', () => {
    const textLength = characterCounter.characterLimit('È') + 1
    const text = new Array(textLength + 1).join('È')
    expect(characterCounter.limitExceeded(text)).toEqual(true)
  })
})
