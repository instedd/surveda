/* eslint-env mocha */
// @flow
import expect from 'expect'
import { newLanguageSelectionStep, newMultipleChoiceStep, newSection } from '../../../../web/static/js/reducers/questionnaire'
import { stepGroups } from '../../../../web/static/js/components/questionnaires/QuestionnaireSteps'

const sectionWithSteps = () => {
  const section = newSection()
  section.steps = [
    newMultipleChoiceStep(),
    newMultipleChoiceStep()
  ]
  return section
}

describe('stepGroups', () => {
  it('puts normal steps without sections and language selection in a single group', () => {
    const steps = [
      newMultipleChoiceStep(),
      newMultipleChoiceStep()
    ]

    const groups = stepGroups(steps)

    expect(groups.length).toEqual(1)
    expect(groups[0].section).toBe(null)
    expect(groups[0].groupSteps).toEqual(steps)
  })

  it('puts language selection is in its own group', () => {
    const steps = [
      newLanguageSelectionStep('en', 'es'),
      newMultipleChoiceStep(),
      newMultipleChoiceStep()
    ]

    const groups = stepGroups(steps)

    expect(groups.length).toEqual(2)
    expect(groups[0].groupSteps.length).toEqual(1)
    expect(groups[0].groupSteps[0]).toEqual(steps[0])
    expect(groups[1].groupSteps.length).toEqual(2)
    expect(groups[1].groupSteps[0]).toEqual(steps[1])
    expect(groups[1].groupSteps[1]).toEqual(steps[2])
  })

  it('puts a section at the beginning and a regular list afterwords', () => {
    const section = sectionWithSteps()

    const steps = [
      section,
      newMultipleChoiceStep(),
      newMultipleChoiceStep()
    ]

    const groups = stepGroups(steps)

    expect(groups.length).toEqual(2)
    expect(groups[0].section).toEqual(section)
    expect(groups[0].groupSteps).toEqual(section.steps)
    expect(groups[1].section).toBe(null)
    expect(groups[1].groupSteps).toEqual([steps[1], steps[2]])
  })

  it('puts a section at the end and a regular list at the beginning', () => {
    const section = sectionWithSteps()

    const steps = [
      newMultipleChoiceStep(),
      newMultipleChoiceStep(),
      section
    ]

    const groups = stepGroups(steps)
    expect(groups.length).toEqual(2)
    expect(groups[0].section).toBe(null)
    expect(groups[0].groupSteps).toEqual([steps[0], steps[1]])
    expect(groups[1].section).toEqual(section)
    expect(groups[1].groupSteps).toEqual(section.steps)
  })

  it('puts two consecutive sections', () => {
    const section1 = sectionWithSteps()
    const section2 = sectionWithSteps()

    const steps = [
      section1,
      section2
    ]

    const groups = stepGroups(steps)

    expect(groups.length).toEqual(2)
    expect(groups[0].section).toEqual(section1)
    expect(groups[1].section).toEqual(section2)
  })

  it('interleaves sections and steps', () => {
    const section1 = sectionWithSteps()
    const section2 = sectionWithSteps()

    const steps = [
      section1,
      newMultipleChoiceStep(),
      section2
    ]

    const groups = stepGroups(steps)

    expect(groups.length).toEqual(3)
    expect(groups[0].section).toEqual(section1)
    expect(groups[1].section).toBe(null)
    expect(groups[1].groupSteps).toEqual([steps[1]])
    expect(groups[2].section).toEqual(section2)
  })

  it('supports empty sections', () => {
    const section = newSection()

    const steps = [
      section,
      newMultipleChoiceStep()
    ]

    const groups = stepGroups(steps)

    expect(groups.length).toEqual(2)
    expect(groups[0].section).toEqual(section)
    expect(groups[0].groupSteps).toEqual([])
    expect(groups[1].section).toBe(null)
    expect(groups[1].groupSteps).toEqual([steps[1]])
  })
})
