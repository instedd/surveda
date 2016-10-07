/* eslint-env mocha */
import expect from 'expect'
import reducer from '../../../web/static/js/reducers/surveyEdit'
import * as actions from '../../../web/static/js/actions/surveyEdit'

describe('surveyEdit reducer', () => {
  it('should toggle a single day preserving the others', () => {
    const result = reducer({survey: {scheduleDayOfWeek: {'mon': true, 'tue': true}}}, actions.toggleDay('wed'))
    expect(result.survey.scheduleDayOfWeek)
    .toEqual({
      'mon': true,
      'tue': true,
      'wed': true
    })
  })
})
