/* eslint-env mocha */
// @flow
import * as surveyModes from '../../../web/static/js/surveyModes'
import expect from 'expect'
import each from 'lodash/each'

describe('survey modes', () => {
  it('returns all possible modes when no one is present', () => {
    const allModes = [
      ['sms'],
      ['sms', 'ivr'],
      ['sms', 'mobileweb'],
      ['ivr'],
      ['ivr', 'sms'],
      ['ivr', 'mobileweb'],
      ['mobileweb'],
      ['mobileweb', 'sms'],
      ['mobileweb', 'ivr']
    ]
    const res = surveyModes.availableOptions([])
    each(allModes, (m) => {
      expect(res).toInclude(m)
    })
  })

  it('returns ivr and mobile web modes when all primary sms modes are selected', () => {
    const ivrAndMobileWebModes = [
      ['ivr'],
      ['ivr', 'sms'],
      ['ivr', 'mobileweb'],
      ['mobileweb'],
      ['mobileweb', 'sms'],
      ['mobileweb', 'ivr']
    ]
    const smsModes = [
      ['sms'],
      ['sms', 'ivr'],
      ['sms', 'mobileweb']
    ]
    const res = surveyModes.availableOptions(smsModes)
    each(ivrAndMobileWebModes, (m) => {
      expect(res).toInclude(m)
    })
    expect(res.length).toEqual(6)
  })
})
