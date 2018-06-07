import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../../actions/survey'
import * as questionnaireActions from '../../actions/questionnaire'
import { hasSections } from '../../reducers/questionnaire'
import * as api from '../../api'
import * as routes from '../../routes'
import { icon } from '../../step'
import { Tooltip, ConfirmationModal, Card, UntitledIfEmpty } from '../ui'
import includes from 'lodash/includes'
import classNames from 'classnames'
import { translate } from 'react-i18next'
import flatten from 'lodash/flatten'

class SurveySimulation extends Component {
  constructor(props) {
    super(props)

    this.state = {
      state: 'pending',
      disposition: 'registered',
      dispositionHistory: ['registered'],
      sectionHistory: [],
      stepId: null,
      sectionIndex: null,
      stepIndex: null,
      responses: {},
      timer: null,
      errorCount: 0
    }
  }

  componentWillMount() {
    const { dispatch, projectId, surveyId } = this.props

    dispatch(actions.fetchSurveyIfNeeded(projectId, surveyId))
    .then(() => {
      const questionnaireId = this.props.survey.questionnaireIds[0]
      dispatch(questionnaireActions.fetchQuestionnaireIfNeeded(projectId, questionnaireId))
    })

    this.refresh()

    const timer = setInterval(() => { this.refresh() }, 5000)
    this.setState({timer})
  }

  componentWillUnmount() {
    if (this.state.timer) {
      clearInterval(this.state.timer)
    }
  }

  refresh() {
    const { projectId, surveyId, questionnaire } = this.props

    api.fetchSurveySimulationStatus(projectId, surveyId)
    .then(status => {
      let dispositionHistory = this.state.dispositionHistory
      let sectionHistory = this.state.sectionHistory
      let sectionIndex = null
      let stepIndex = status.step_index

      if (status.disposition != this.state.disposition) {
        dispositionHistory = [...dispositionHistory, status.disposition]
      }

      if (questionnaire && status.step_index && hasSections(questionnaire.steps)) {
        sectionIndex = status.step_index[0]
        stepIndex = status.step_index[1]
        if (!sectionHistory.includes(sectionIndex)) {
          sectionHistory = [...sectionHistory, sectionIndex]
        }
      }

      this.setState({
        state: status.state,
        disposition: status.disposition,
        dispositionHistory: dispositionHistory,
        sectionHistory: sectionHistory,
        stepId: status.step_id,
        stepIndex: stepIndex,
        sectionIndex: sectionIndex,
        responses: status.responses,
        errorCount: 0
      })
    }, error => {
      if (this.state.errorCount >= 2) {
        // Three errors occurred in a row. Raise the error here.
        return Promise.reject(error)
      } else {
        this.setState(prevState => ({errorCount: prevState.errorCount + 1}))
      }
    })
  }

  stopSimulation(e) {
    e.preventDefault()

    const { router, projectId, surveyId, t } = this.props

    const stopSimulationModal = this.refs.stopSimulationModal
    stopSimulationModal.open({
      modalText: <span>
        <p>{t('Are you sure you want to stop the simulation')}</p>
      </span>,
      onConfirm: () => {
        api.stopSurveySimulation(projectId, surveyId)
        .then((response) => {
          router.replace(routes.questionnaire(projectId, response.questionnaire_id))
        })
      }
    })
  }

  stepsComponent() {
    const { questionnaire } = this.props

    if (!questionnaire) return null
    let stepList = null
    if (hasSections(questionnaire.steps)) {
      stepList = flatten(questionnaire.steps.map((step, index) => this.stepsComponentWhenSections(step, index)))
    } else {
      stepList = questionnaire.steps.map((step, index) => this.stepComponent(step, index))
    }

    return (
      <Card>
        <ul className='collection simulation'>
          {stepList}
        </ul>
      </Card>
    )
  }

  stepsComponentWhenSections(step, index) {
    const sectionHistory = this.state.sectionHistory
    const sectionIndex = this.state.sectionIndex
    const stepIndex = this.state.stepIndex
    const stepList = []
    let className = 'collection-item'
    let iconValue = icon(step.type)
    if (step.type === 'language-selection') {
      if (index == sectionIndex) {
        className = className + ' active'
      } else if (this.state.disposition === 'completed' || index < sectionIndex) {
        className += ' done'
        iconValue = 'check_circle'
      }
      stepList.push(this.stepItem(step, this.state.responses[step.store], 0, className, iconValue))
    } else if (step.type === 'section') {
      // add the section step to the stepList
      stepList.push(this.stepItem(step, null, index, className, iconValue))
      let value = null
      for (let i = 0; i < step.steps.length; i++) {
        const stepInSection = step.steps[i]
        value = this.state.responses[stepInSection.store]
        className = 'collection-item'
        iconValue = icon(stepInSection.type)
        if (sectionHistory.includes(index)) {
          if (index !== sectionIndex || this.state.disposition === 'completed') {
            // scope: inside a section that has already been executed
            [className, iconValue] = this.computeClassNameAndIcon(value, className, iconValue)
          } else if (index == sectionIndex) {
            // scope: inside the section that is been executed at this moment
            if (i < stepIndex) {
              [className, iconValue] = this.computeClassNameAndIcon(value, className, iconValue)
            } else if (i == stepIndex) {
              className += ' active'
            }
          }
        }
        // add each of the steps inside the section to the steplist
        stepList.push(this.stepItem(stepInSection, value, `${index}${i}`, className, iconValue))
      }
    }
    return stepList
  }

  computeClassNameAndIcon(value, className, iconValue) {
    let newClassName = null
    let newIconValue = null
    if (value) {
      newClassName = className + ' done'
      newIconValue = 'check_circle'
    } else {
      newClassName = className + ' skipped'
      newIconValue = iconValue
    }
    return [newClassName, newIconValue]
  }

  stepComponent(step, index) {
    let className = 'collection-item'
    let iconValue = icon(step.type)
    const stepIndex = this.state.stepIndex

    const value = this.state.responses[step.store]

    if ((stepIndex && index < stepIndex) || this.state.disposition === 'completed') {
      [className, iconValue] = this.computeClassNameAndIcon(value, className, iconValue)
    } else if (this.state.stepId == step.id) {
      className += ' active'
    }

    return this.stepItem(step, value, index, className, iconValue)
  }

  stepItem(step, value, key, className, iconValue) {
    const { t } = this.props
    return (
      <li className={className} key={key}>
        <i className='material-icons left sharp'>{iconValue}</i>
        <UntitledIfEmpty className='title' text={step.title} emptyText={t('Untitled question')} />
        <br />
        <span className='value'>{value}</span>
      </li>
    )
  }

  render() {
    const { t } = this.props
    return (
      <div>
        <Tooltip text={t('Stop simulation')}>
          <a className='btn-floating btn-large waves-effect waves-light red right mtop' onClick={(e) => this.stopSimulation(e)}>
            <i className='material-icons'>clear</i>
          </a>
        </Tooltip>
        <ConfirmationModal modalId='survey_stop_simulation_modal' ref='stopSimulationModal' confirmationText={t('Stop')} header={t('Stop simulation')} showCancel />

        <div className='row'>
          <div className='col s12 m4'>
            <h4>{t('Disposition')}</h4>
            <ul className='disposition radio-no-pointer'>
              <li>
                <div className='row'>
                  <div className='col s3'>
                    <p>{t('Uncontacted')}</p>
                  </div>
                  <div className='col s9'>
                    <ul>
                      <li className={classNames({'active': this.state.disposition == 'registered'})}>
                        <input
                          id='registered'
                          type='radio'
                          name='registered'
                          value='default'
                          readOnly
                          checked={includes(this.state.dispositionHistory, 'registered')}
                          className='with-gap'
                        />
                        <label htmlFor='registered'>{t('Registered')}</label>
                      </li>
                      <li className={classNames({'active': this.state.disposition == 'queued'})}>
                        <input
                          id='queued'
                          type='radio'
                          name='queued'
                          value='default'
                          readOnly
                          checked={includes(this.state.dispositionHistory, 'queued')}
                          className='with-gap'
                        />
                        <label htmlFor='queued'>{t('Queued')}</label>
                        <ul>
                          <li className={classNames({'active': this.state.disposition == 'failed'})}>
                            <input
                              id='failed'
                              type='radio'
                              name='failed'
                              value='default'
                              readOnly
                              checked={includes(this.state.dispositionHistory, 'failed')}
                              className='with-gap'
                            />
                            <label htmlFor='failed'>{t('Failed')}</label>
                          </li>
                        </ul>
                      </li>
                    </ul>
                  </div>
                </div>
              </li>
              <li>
                <div className='row'>
                  <div className='col s3'>
                    <p>{t('Contacted')}</p>
                  </div>
                  <div className='col s9'>
                    <ul>
                      <li className={classNames({'active': this.state.disposition == 'contacted'})}>
                        <input
                          id='contacted'
                          type='radio'
                          name='contacted'
                          value='default'
                          readOnly
                          checked={includes(this.state.dispositionHistory, 'contacted')}
                          className='with-gap'
                        />
                        <label htmlFor='contacted'>{t('Contacted')}</label>
                        <ul>
                          <li className={classNames({'active': this.state.disposition == 'unresponsive'})}>
                            <input
                              id='unresponsive'
                              type='radio'
                              name='unresponsive'
                              value='default'
                              readOnly
                              checked={includes(this.state.dispositionHistory, 'unresponsive')}
                              className='with-gap'
                            />
                            <label htmlFor='unresponsive'>{t('Unresponsive')}</label>
                          </li>
                        </ul>
                      </li>
                    </ul>
                  </div>
                </div>
              </li>
              <li>
                <div className='row'>
                  <div className='col s3'>
                    <p>{t('Responsive')}</p>
                  </div>
                  <div className='col s9'>
                    <ul className='last'>
                      <li className={classNames({'active': this.state.disposition == 'started'})}>
                        <input
                          id='started'
                          type='radio'
                          name='started'
                          value='default'
                          readOnly
                          checked={includes(this.state.dispositionHistory, 'started')}
                          className='with-gap'
                        />
                        <label htmlFor='started'>{t('Started')}</label>
                        <ul>
                          <li className={classNames({'active': this.state.disposition == 'refused'})}>
                            <input
                              id='refused'
                              type='radio'
                              name='refused'
                              value='default'
                              readOnly
                              checked={includes(this.state.dispositionHistory, 'refused')}
                              className='with-gap'
                            />
                            <label htmlFor='refused'>{t('Refused')}</label>
                          </li>
                          <li className={classNames({'active': this.state.disposition == 'ineligible'})}>
                            <input
                              id='ineligible'
                              type='radio'
                              name='ineligible'
                              value='default'
                              readOnly
                              checked={includes(this.state.dispositionHistory, 'ineligible')}
                              className='with-gap'
                            />
                            <label htmlFor='ineligible'>{t('Ineligible')}</label>
                          </li>
                          <li className={classNames({'active': this.state.disposition == 'rejected'})}>
                            <input
                              id='rejected'
                              type='radio'
                              name='rejected'
                              value='default'
                              readOnly
                              checked={includes(this.state.dispositionHistory, 'rejected')}
                              className='with-gap'
                            />
                            <label htmlFor='rejected'>{t('Rejected')}</label>
                          </li>
                          <li className={classNames({'active': this.state.disposition == 'breakoff'})}>
                            <input
                              id='breakoff'
                              type='radio'
                              name='breakoff'
                              value='default'
                              readOnly
                              checked={includes(this.state.dispositionHistory, 'breakoff')}
                              className='with-gap'
                            />
                            <label htmlFor='breakoff'>{t('Breakoff')}</label>
                          </li>
                        </ul>
                      </li>
                      <li className={classNames({'active': this.state.disposition == 'interim partial'})}>
                        <input
                          id='interim partial'
                          type='radio'
                          name='interim partial'
                          value='default'
                          readOnly
                          checked={includes(this.state.dispositionHistory, 'interim partial')}
                          className='with-gap'
                        />
                        <label htmlFor='partial'>{t('Interim Partial')}</label>
                        <ul>
                          <li className={classNames({'active': this.state.disposition == 'partial'})}>
                            <input
                              id='partial'
                              type='radio'
                              name='partial'
                              value='default'
                              readOnly
                              checked={includes(this.state.dispositionHistory, 'partial')}
                              className='with-gap'
                            />
                            <label htmlFor='partial'>{t('Partial')}</label>
                          </li>
                        </ul>
                      </li>
                      <li className={classNames({'active': this.state.disposition == 'completed'})}>
                        <input
                          id='completed'
                          type='radio'
                          name='completed'
                          value='default'
                          readOnly
                          checked={includes(this.state.dispositionHistory, 'completed')}
                          className='with-gap'
                        />
                        <label htmlFor='completed'>{t('Completed')}</label>
                      </li>
                    </ul>
                  </div>
                </div>
              </li>
            </ul>
          </div>
          <div className='col s12 m8'>
            {this.stepsComponent()}
          </div>
        </div>
      </div>
    )
  }
}

SurveySimulation.propTypes = {
  t: PropTypes.func,
  dispatch: PropTypes.func,
  router: PropTypes.object,
  projectId: PropTypes.string,
  surveyId: PropTypes.string,
  survey: PropTypes.object,
  questionnaire: PropTypes.object
}

const mapStateToProps = (state, ownProps) => {
  return {
    projectId: ownProps.params.projectId,
    surveyId: ownProps.params.surveyId,
    survey: state.survey.data,
    questionnaire: state.questionnaire.data
  }
}

export default translate()(withRouter(connect(mapStateToProps)(SurveySimulation)))
