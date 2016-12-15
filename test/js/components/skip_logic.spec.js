/* eslint-env mocha */
// @flow
import React from 'react'
import expect from 'expect'
import { shallow } from 'enzyme'
import SkipLogic from '../../../web/static/js/components/questionnaires/SkipLogic'
import { questionnaire } from '../fixtures'

const skipTo = (item, wrapper) => {
  const skip = {target: {value: item}}
  wrapper.simulate('change', skip)
}

describe('<SkipLogic/>', () => {
  it('triggers onChange with null if chosen option has empty value', () => {
    const step1 = questionnaire.steps[0]
    const step2 = questionnaire.steps[1]

    let lastChange
    const wrapper =
      shallow(
        <SkipLogic
          stepsAfter={[step1, step2]}
          onChange={(value) => {
            lastChange = value
            return
          }}
          value={null} />
        )

    expect(wrapper.state()['value']).toEqual(null)

    skipTo(step2.id, wrapper)
    expect(lastChange).toEqual(step2.id)

    skipTo('', wrapper)
    expect(lastChange).toEqual(null)
  })
})

