// @flow
import React, { Component } from 'react'
import StepEditor from './StepEditor'
import StepsList from './StepsList'
import { hasSections } from '../../reducers/questionnaire'
import { DragDropContext } from 'react-dnd'
import HTML5Backend from 'react-dnd-html5-backend'
import DraggableStep from './DraggableStep'
import Section from './Section'

type Props = {
  steps: Step[],
  errorPath: string,
  errorsByPath: ErrorsByPath,
  readOnly: boolean,
  onSelectStep: Function,
  onDeselectStep: Function,
  onDeleteStep: Function,
  readOnly: boolean,
  quotaCompletedSteps?: boolean,
  increaseErrorIndex?: boolean,
  sectionId?: string,
  selectedSteps: Object
};

type StepGroup = {
  section: ?SectionStep,
  groupSteps: Step[]
};

// This function is here because I think it is too ad-hoc
// to put it closer to the model.
export const stepGroups = (steps: Step[]): StepGroup[] => {
  // Some auxiliaries for better readability
  const lastGroupIsSection = (groups) => groups[groups.length - 1].section !== null
  const lastGroupIsForLanguageSelection = (groups) => !lastGroupIsSection(groups) && groups[groups.length - 1].groupSteps[0].type === 'language-selection'

  const groups = steps.reduce((groups: StepGroup[], step: Step) => {
    if (step.type === 'section') {
      groups.push({ section: step, groupSteps: step.steps })
    } else if (step.type === 'language-selection' ||
                groups.length == 0 ||
                lastGroupIsForLanguageSelection(groups) ||
                lastGroupIsSection(groups)) {
      groups.push({ section: null, groupSteps: [step] })
    } else {
      groups[groups.length - 1].groupSteps.push(step)
    }

    return groups
  }, [])

  return groups
}

class QuestionnaireSteps extends Component<Props> {
  render() {
    const { steps, errorPath, errorsByPath, readOnly, quotaCompletedSteps, selectedSteps, onSelectStep, onDeselectStep, onDeleteStep } = this.props

    const groups = stepGroups(steps)
    const increaseErrorIndex = (steps.length > 0) && !hasSections(steps) && steps[0].type == 'language-selection'

    return (
      <div>
        { groups.map((item, index) => (
          item.section != null
            ? <Section title={item.section.title} randomize={item.section.randomize} key={item.section.id} id={item.section.id} readOnly={readOnly}>
              <QuestionnaireStepsGroup
                steps={item.groupSteps}
                errorPath={`${errorPath}[${index}].steps`}
                errorsByPath={errorsByPath}
                onDeleteStep={onDeleteStep}
                onSelectStep={onSelectStep}
                onDeselectStep={onDeselectStep}
                readOnly={readOnly}
                selectedSteps={selectedSteps}
                quotaCompletedSteps={quotaCompletedSteps}
                sectionId={item.section.id}
              />
            </Section>
          : <QuestionnaireStepsGroup
            key={index}
            steps={item.groupSteps}
            errorPath={errorPath}
            errorsByPath={errorsByPath}
            increaseErrorIndex={increaseErrorIndex && item.groupSteps[0].type != 'language-selection'}
            onDeleteStep={onDeleteStep}
            onSelectStep={onSelectStep}
            onDeselectStep={onDeselectStep}
            readOnly={readOnly}
            selectedSteps={selectedSteps}
            quotaCompletedSteps={quotaCompletedSteps}
          />

        ))}
      </div>
    )
  }
}

class QuestionnaireStepsGroup extends Component<Props> {
  dummyDropTarget() {
    const { steps, readOnly, quotaCompletedSteps, sectionId = null } = this.props

    if (steps && steps.length > 0 && steps[0].type != 'language-selection') {
      return (
        <DraggableStep step={null} sectionId={sectionId} readOnly={readOnly} quotaCompletedSteps={quotaCompletedSteps}>
          <div style={{borderBottom: 'solid transparent'}} />
        </DraggableStep>
      )
    }

    return <div />
  }

  questionnaireStepsGroup() {
    const { steps, errorPath, errorsByPath, increaseErrorIndex, readOnly, quotaCompletedSteps, selectedSteps, onSelectStep, onDeselectStep, onDeleteStep } = this.props

    const current = selectedSteps.currentStepId
    const currentStepIsNew = selectedSteps.currentStepIsNew
    const itemIndex = steps.findIndex(step => step.id == current)
    const errorIndex = increaseErrorIndex ? itemIndex + 1 : itemIndex

    if (current == null || itemIndex < 0) {
      // All collapsed
      return <StepsList steps={steps} errorPath={errorPath} onClick={onSelectStep} readOnly={readOnly} quotaCompletedSteps={quotaCompletedSteps} increaseErrorIndex={increaseErrorIndex} />
    } else {
      // Only one expanded
      const stepsBefore = steps.slice(0, itemIndex)
      const currentStep = steps[itemIndex]
      const stepsAfter = steps.slice(itemIndex + 1)

      return (
        <div>
          <StepsList steps={stepsBefore} errorPath={errorPath} onClick={onSelectStep} readOnly={readOnly} quotaCompletedSteps={quotaCompletedSteps} increaseErrorIndex={increaseErrorIndex} />
          <StepEditor
            step={currentStep}
            stepIndex={itemIndex}
            errorPath={`${errorPath}[${errorIndex}]`}
            errorsByPath={errorsByPath}
            readOnly={readOnly}
            quotaCompletedSteps={!!quotaCompletedSteps}
            isNew={currentStepIsNew}
            onCollapse={onDeselectStep}
            onDelete={onDeleteStep}
            stepsAfter={stepsAfter}
            stepsBefore={stepsBefore} />
          <StepsList steps={stepsAfter} startIndex={itemIndex + 1} errorPath={errorPath} onClick={onSelectStep} readOnly={readOnly} quotaCompletedSteps={quotaCompletedSteps} increaseErrorIndex={increaseErrorIndex} />
        </div>
      )
    }
  }

  render() {
    return (
      <div>
        {this.dummyDropTarget()}
        {this.questionnaireStepsGroup()}
      </div>
    )
  }
}

export default DragDropContext(HTML5Backend)(QuestionnaireSteps)
