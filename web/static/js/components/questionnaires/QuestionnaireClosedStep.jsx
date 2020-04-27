// @flow
import React, { Component } from 'react'
import classNames from 'classnames'
import { UntitledIfEmpty, Card, Tooltip } from '../ui'
import { icon } from '../../step'
import DraggableStep from './DraggableStep'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import * as questionnaireActions from '../../actions/questionnaire'
import { hasErrorsInPrefixWithModeAndLanguage } from '../../questionnaireErrors'
import withQuestionnaire from './withQuestionnaire'
import { translate } from 'react-i18next'
import { canBeRelevant } from '../../reducers/questionnaire'

type Props = {
  t: Function,
  step: Step,
  stepIndex: number,
  errorPath: string,
  onClick: Function,
  hasErrors: boolean,
  readOnly: boolean,
  quotaCompletedSteps: boolean,
  partialRelevantEnabled: boolean,
  questionnaireActions: any
};

class QuestionnaireClosedStep extends Component<Props> {
  stepRelevantSubmit(value) {
    this.props.questionnaireActions.changeStepRelevant(this.props.step.id, value)
  }

  render() {
    const { step, onClick, hasErrors, readOnly, quotaCompletedSteps, partialRelevantEnabled, t } = this.props

    const stepIconClass = classNames({
      'material-icons left': true,
      'sharp': step.type === 'numeric' || step.type == 'explanation',
      'text-error': hasErrors
    })

    const renderRelevant = relevant =>
      <a href='#!'
        className=''
        onClick={e => {
          e.preventDefault()
          e.stopPropagation()
          this.stepRelevantSubmit(!relevant)
        }}>
        <Tooltip text={relevant ? 'This question is relevant for partial flag' : 'This question is not relevant for partial flag'}>
          <i className={`material-icons right ${relevant ? 'green-text darken-2' : 'grey-text darken-3'}`}>star</i>
        </Tooltip>
      </a>

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
                {partialRelevantEnabled && canBeRelevant(step.type) ? renderRelevant(step.relevant) : null}
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

const mapDispatchToProps = dispatch => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default translate()(withQuestionnaire(connect(mapStateToProps, mapDispatchToProps)(QuestionnaireClosedStep)))
