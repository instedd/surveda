// @flow
import React, { Component } from 'react'
import classNames from 'classnames'
import { UntitledIfEmpty, Card, appliesRelevant, Tooltip } from '../ui'
import { icon } from '../../step'
import DraggableStep from './DraggableStep'
import { connect } from 'react-redux'
import { hasErrorsInPrefixWithModeAndLanguage } from '../../questionnaireErrors'
import withQuestionnaire from './withQuestionnaire'
import { translate } from 'react-i18next'

type Props = {
  t: Function,
  step: Step,
  stepIndex: number,
  errorPath: string,
  onClick: Function,
  hasErrors: boolean,
  readOnly: boolean,
  quotaCompletedSteps: boolean,
  partialRelevantEnabled: boolean
};

class QuestionnaireClosedStep extends Component<Props> {
  render() {
    const { step, onClick, hasErrors, readOnly, quotaCompletedSteps, partialRelevantEnabled, t } = this.props

    const stepIconClass = classNames({
      'material-icons left': true,
      'sharp': step.type === 'numeric' || step.type == 'explanation',
      'text-error': hasErrors
    })

    const renderRelevant = relevant =>
      <Tooltip text={relevant ? 'Partial relevant' : 'Not partial relevant'}>
        <i className={`material-icons right ${relevant ? 'green-text darken-2' : 'grey-text darken-3'}`}>star</i>
      </Tooltip>

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
                <UntitledIfEmpty className={classNames({'text-error': hasErrors})} text={step.title} emptyText={t('Untitled question')} />
                <i className={classNames({'material-icons right grey-text': true, 'text-error': hasErrors})}>expand_more</i>
                {partialRelevantEnabled && appliesRelevant(step.type) ? renderRelevant(step.relevant) : null}
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
  let lang = ownProps.questionnaire.activeLanguage
  let mode = ownProps.questionnaire.activeMode
  if (ownProps.step.type == 'language-selection') {
    lang = null
  }
  const questionnaire = state.questionnaire && state.questionnaire.data
  return {
    hasErrors: hasErrorsInPrefixWithModeAndLanguage(state.questionnaire.errors, ownProps.errorPath, mode, lang),
    partialRelevantEnabled: questionnaire && questionnaire.partialRelevantConfig && questionnaire.partialRelevantConfig.enabled
  }
}

export default translate()(withQuestionnaire(connect(mapStateToProps)(QuestionnaireClosedStep)))
