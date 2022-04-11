/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../assets/js/reducers/timezones'
import * as actions from '../../../assets/js/actions/timezones'

describe('timezones reducer', () => {
  it('should receive timezones', () => {
    const data = { timezones: [
      'Africa/Abidjan',
      'Africa/Accra',
      'Africa/Addis_Ababa',
      'Africa/Algiers',
      'Africa/Asmara']
    }
    const result = reducer({}, actions.receiveTimezones(data))
    expect(result.items).toEqual(data.timezones)
  })

  it('should start fetching timezones', () => {
    const result = reducer({fecthing: false}, actions.startFetchingTimezones())
    expect(result.fetching)
  })
})
