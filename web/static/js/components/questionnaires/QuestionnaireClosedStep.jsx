// @flow
import React, { Component } from 'react'
import classNames from 'classnames'
import { UntitledIfEmpty, Card } from '../ui'
import DraggableStep from './DraggableStep'
import { connect } from 'react-redux'
import { hasErrorsInPrefixWithLanguage } from '../../questionnaireErrors'

type Props = {
  step: Step,
  stepIndex: number,
  errorPath: string,
  onClick: Function,
  hasErrors: boolean,
  readOnly: boolean,
  quotaCompletedSteps: boolean
};

class QuestionnaireClosedStep extends Component {
  props: Props

  render() {
    const { step, onClick, hasErrors, readOnly, quotaCompletedSteps } = this.props

    const stepIconClass = classNames({
      'material-icons left': true,
      'sharp': step.type === 'numeric' || step.type == 'explanation',
      'text-error': hasErrors
    })

    const stepIconFont = (() => {
      switch (step.type) {
        case 'multiple-choice':
          return 'list'
        case 'numeric':
          return 'dialpad'
        case 'explanation':
          return 'chat_bubble_outline'
        case 'flag':
          return 'flag'
        case 'language-selection':
          return 'language'
        default:
          throw new Error(`unknown step type: ${step.type}`)
      }
    })()

    return (
      <DraggableStep step={step} readOnly={readOnly} quotaCompletedSteps={quotaCompletedSteps}>
        <Card>
          <div className='card-content closed-step'>
            <div>
              <a href='#!' className='truncate' onClick={event => {
                event.preventDefault()
                onClick(step.id)
              }}>
                <i className={stepIconClass}>{stepIconFont}</i>
                <UntitledIfEmpty className={classNames({'text-error': hasErrors})} text={step.title} entityName='question' />
                <i className={classNames({'material-icons right grey-text': true, 'text-error': hasErrors})}>expand_more</i>
              </a>
            </div>
          </div>
        </Card>
      </DraggableStep>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  hasErrors: hasErrorsInPrefixWithLanguage(state.questionnaire.errors, ownProps.errorPath, (state.questionnaire.data || {}).activeLanguage)
})

export default connect(mapStateToProps)(QuestionnaireClosedStep)
