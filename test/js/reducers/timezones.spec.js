/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../web/static/js/reducers/timezones'
import * as actions from '../../../web/static/js/actions/timezones'

describe('respondents reducer', () => {
  it('should receive timezones', () => {
    const data = { timezones: [
      'Africa/Abidjan',
      'Africa/Accra',
      'Africa/Addis_Ababa',
      'Africa/Algiers',
      'Africa/Asmara']
    }
    const result = reducer({}, actions.receiveTimezones(data))
    expect(result.timezones).toEqual(data.timezones)
  })
})
