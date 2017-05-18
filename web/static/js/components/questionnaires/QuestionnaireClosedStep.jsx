// @flow
import React, { Component } from 'react'
import classNames from 'classnames'
import { UntitledIfEmpty, Card } from '../ui'
import { icon } from '../../step'
import DraggableStep from './DraggableStep'
import { connect } from 'react-redux'
import { hasErrorsInPrefixWithModeAndLanguage } from '../../questionnaireErrors'

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

    const stepIconFont = icon(step.type)

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

const mapStateToProps = (state, ownProps) => {
  // For a language-selection step the errors are without a language
  let lang = (state.questionnaire.data || {}).activeLanguage
  let mode = (state.questionnaire.data || {}).activeMode
  if (ownProps.step.type == 'language-selection') {
    lang = null
  }
  return {
    hasErrors: hasErrorsInPrefixWithModeAndLanguage(state.questionnaire.errors, ownProps.errorPath, mode, lang)
  }
}

export default connect(mapStateToProps)(QuestionnaireClosedStep)
