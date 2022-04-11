/* eslint-env mocha */
// @flow
import expect from 'expect'
import * as characterCounter from '../../../assets/js/characterCounter'

describe('characterCounter', () => {
  it('character count is 0 with empty string', () => {
    expect(characterCounter.count('').count).toEqual(0)
  })

  it('limit is 160 for GSM 03.38 character set', () => {
    const gsm0338String = 'This is a standard SMS text. Can also includes some symbols like $%^&-_[][]!?'
    expect(characterCounter.count(gsm0338String).limit).toEqual(160)
  })

  it('limit is 70 if at least one character is Unicode', () => {
    const unicodeString = 'It contains È with french grave accent'
    expect(characterCounter.count(unicodeString).limit).toEqual(70)
  })

  it('computes character count for text of length below the limit for GSM 03.38 character set', () => {
    const textLength = 50
    const text = 'a'.repeat(textLength)
    expect(characterCounter.count(text).count).toEqual(textLength)
  })

  it('computes if limit was exceeded for text of length below the limit for GSM 03.38 character set', () => {
    const textLength = 50
    const text = 'a'.repeat(textLength)
    expect(characterCounter.limitExceeded(text)).toEqual(false)
  })

  it('computes character count for text of length below the limit for Unicode character set', () => {
    const textLength = 50
    const text = 'È'.repeat(textLength)
    expect(characterCounter.count(text).count).toEqual(textLength)
  })

  it('computes if limit was exceeded for text of length below the limit for Unicode character set', () => {
    const textLength = 50
    const text = 'È'.repeat(textLength)
    expect(characterCounter.limitExceeded(text)).toEqual(false)
  })

  it('computes character count for text of length equal to the GSM 03.38 limit', () => {
    const textLength = characterCounter.gsm0338Limit
    const text = 'a'.repeat(textLength)
    expect(characterCounter.count(text).count).toEqual(textLength)
  })

  it('computes if limit was exceeded for text of length equal to the GSM 03.38 limit', () => {
    const textLength = characterCounter.gsm0338Limit
    const text = 'a'.repeat(textLength)
    expect(characterCounter.limitExceeded(text)).toEqual(false)
  })

  it('computes character count for text of length equal to the Unicode limit', () => {
    const textLength = characterCounter.unicodeLimit
    const text = 'È'.repeat(textLength)
    expect(characterCounter.count(text).count).toEqual(textLength)
  })

  it('computes if limit was exceeded for text of length equal to the Unicode limit', () => {
    const textLength = characterCounter.unicodeLimit
    const text = 'È'.repeat(textLength)
    expect(characterCounter.limitExceeded(text)).toEqual(false)
  })

  it('computes character count for text longer than the GSM 03.38 limit', () => {
    const textLength = characterCounter.gsm0338Limit + 1
    const text = 'a'.repeat(textLength)
    expect(characterCounter.count(text).count).toEqual(textLength)
  })

  it('computes if limit was exceeded for text longer than the GSM 03.38 limit', () => {
    const textLength = characterCounter.gsm0338Limit + 1
    const text = 'a'.repeat(textLength)
    expect(characterCounter.limitExceeded(text)).toEqual(true)
  })

  it('computes character count for text longer than the Unicode limit', () => {
    const textLength = characterCounter.unicodeLimit + 1
    const text = 'È'.repeat(textLength)
    expect(characterCounter.count(text).count).toEqual(textLength)
  })

  it('computes if limit was exceeded for text longer than the Unicode limit', () => {
    const textLength = characterCounter.gsm0338Limit + 1
    const text = 'È'.repeat(textLength)
    expect(characterCounter.limitExceeded(text)).toEqual(true)
  })

  it('computes if limit was exceeded for text longer than the Unicode limit', () => {
    const textLength = characterCounter.gsm0338Limit + 1
    const text = 'È'.repeat(textLength)
    expect(characterCounter.limitExceeded(text)).toEqual(true)
  })

  it('computes character count when text of length below the limit includes chars that count by 2 ', () => {
    const text = '[]'.repeat(30) + 'a'
    expect(characterCounter.count(text).count).toEqual(121)
  })

  it('computes character count when text of length equal to the limit includes chars that count by 2 ', () => {
    const text = '[]'.repeat(40)
    expect(characterCounter.count(text).count).toEqual(characterCounter.gsm0338Limit)
  })

  it('computes character count when text of length longer than the limit includes chars that count by 2 ', () => {
    const text = '[]'.repeat(40) + 'a'
    expect(characterCounter.count(text).count).toEqual(characterCounter.gsm0338Limit + 1)
  })
})
