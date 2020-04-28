import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as questionnaireActions from '../../actions/questionnaire'
import { EditableTitleLabel, Card, Tooltip } from '../ui'
import { translate } from 'react-i18next'
import { canBeRelevant } from '../../reducers/questionnaire'

class StepCard extends Component {
  stepTitleSubmit(value) {
    const { stepId } = this.props
    this.props.questionnaireActions.changeStepTitle(stepId, value)
  }

  stepRelevantSubmit(value) {
    const { stepId } = this.props
    this.props.questionnaireActions.changeStepRelevant(stepId, value)
  }

  render() {
    const { onCollapse, stepId, children, icon, stepTitle, readOnly, t, relevant, stepType, partialRelevantEnabled } = this.props
    const renderRelevant = relevant =>
      <button type='button'
        className='partial-relevant-button right'
        onClick={e => {
          e.preventDefault()
          this.stepRelevantSubmit(!relevant)
        }}>
        <Tooltip text={relevant ? t('This question is relevant for partial flag') : t('This question is not relevant for partial flag')}>
          <i className={`material-icons ${relevant ? 'green-text darken-2' : 'grey-text darken-3'}`}>star</i>
        </Tooltip>
      </button>

    return (
      <Card key={stepId}>
        <ul className='collection collection-card' id={`step-id-${stepId}`}>
          <li className='collection-item input-field header'>
            <div className='row'>
              <div className='col s12'>
                {icon}
                <EditableTitleLabel className='editable-field' title={stepTitle} readOnly={readOnly} emptyText={t('Untitled question')} onSubmit={value => this.stepTitleSubmit(value)} />
                <a href='#!'
                  className=''
                  onClick={e => {
                    e.preventDefault()
                    onCollapse()
                  }}>
                  <i className='material-icons collapse right'>expand_less</i>
                </a>
                {partialRelevantEnabled && canBeRelevant(stepType) ? renderRelevant(relevant) : null}
              </div>
            </div>
          </li>
          {children}
        </ul>
      </Card>
    )
  }
}

StepCard.propTypes = {
  t: PropTypes.func,
  icon: PropTypes.object.isRequired,
  stepTitle: PropTypes.string.isRequired,
  stepId: PropTypes.any.isRequired,
  children: PropTypes.node,
  onCollapse: PropTypes.func.isRequired,
  questionnaireActions: PropTypes.any,
  readOnly: PropTypes.bool,
  relevant: PropTypes.bool,
  stepType: PropTypes.string,
  partialRelevantEnabled: PropTypes.bool
}

const mapStateToProps = state => {
  const questionnaire = state.questionnaire && state.questionnaire.data
  return {
    partialRelevantEnabled: questionnaire && questionnaire.partialRelevantConfig && questionnaire.partialRelevantConfig.enabled
  }
}

const mapDispatchToProps = dispatch => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default translate()(connect(mapStateToProps, mapDispatchToProps)(StepCard))
