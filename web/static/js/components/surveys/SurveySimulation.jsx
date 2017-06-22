import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../../actions/survey'
import * as questionnaireActions from '../../actions/questionnaire'
import * as api from '../../api'
import * as routes from '../../routes'
import { icon } from '../../step'
import { Tooltip, ConfirmationModal, Card } from '../ui'
import includes from 'lodash/includes'
import classNames from 'classnames'

class SurveySimulation extends Component {
  constructor(props) {
    super(props)

    this.state = {
      state: 'pending',
      disposition: 'registered',
      dispositionHistory: ['registered'],
      stepId: null,
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
    const { projectId, surveyId } = this.props

    api.fetchSurveySimulationStatus(projectId, surveyId)
    .then(status => {
      let dispositionHistory = this.state.dispositionHistory

      if (status.disposition != this.state.disposition) {
        dispositionHistory += status.disposition
      }

      this.setState({
        state: status.state,
        disposition: status.disposition,
        dispositionHistory: dispositionHistory,
        stepId: status.step_id,
        stepIndex: status.step_index,
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

    const { router, projectId, surveyId } = this.props

    const stopSimulationModal = this.refs.stopSimulationModal
    stopSimulationModal.open({
      modalText: <span>
        <p>Are you sure you want to stop the simulation</p>
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

    return (
      <Card>
        <ul className='collection simulation'>
          {questionnaire.steps.map((step, index) => this.stepComponent(step, index))}
        </ul>
      </Card>
    )
  }

  stepComponent(step, index) {
    let className = 'collection-item'
    let iconValue = icon(step.type)

    const value = this.state.responses[step.store]

    if (this.state.stepIndex && index < this.state.stepIndex) {
      if (value) {
        className += ' done'
        iconValue = 'check_circle'
      } else {
        className += ' skipped'
      }
    } else if (this.state.stepId == step.id) {
      className += ' active'
    }

    return (
      <li className={className} key={index}>
        <i className='material-icons left sharp'>{iconValue}</i>
        <span className='title'>{step.title}</span>
        <br />
        <span className='value'>{value}</span>
      </li>
    )
  }

  render() {
    return (
      <div>
        <Tooltip text='Stop simulation'>
          <a className='btn-floating btn-large waves-effect waves-light red right mtop' onClick={(e) => this.stopSimulation(e)}>
            <i className='material-icons'>clear</i>
          </a>
        </Tooltip>
        <ConfirmationModal modalId='survey_stop_simulation_modal' ref='stopSimulationModal' confirmationText='STOP' header='Stop simulation' showCancel />

        <div className='row'>
          <div className='col s12 m4'>
            <h4>
              Disposition
            </h4>
            <p> {
              // this.state.disposition
            } </p>
            <ul className='disposition'>
              <li>
                <div className='row'>
                  <div className='col s3'>
                    <p>
                      Uncontacted
                    </p>
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
                        <label htmlFor='registered'>Registered</label>
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
                        <label htmlFor='queued'>Queued</label>
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
                            <label htmlFor='failed'>Failed</label>
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
                    <p>
                      Contacted
                    </p>
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
                        <label htmlFor='contacted'>Contacted</label>
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
                            <label htmlFor='unresponsive'>Unresponsive</label>
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
                    <p>
                      Responsive
                    </p>
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
                        <label htmlFor='started'>Started</label>
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
                            <label htmlFor='refused'>Refused</label>
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
                            <label htmlFor='ineligible'>Ineligible</label>
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
                            <label htmlFor='rejected'>Rejected</label>
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
                            <label htmlFor='breakoff'>Breakoff</label>
                          </li>
                        </ul>
                      </li>
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
                        <label htmlFor='partial'>Partial</label>
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
                        <label htmlFor='completed'>Completed</label>
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
  dispatch: React.PropTypes.func,
  router: React.PropTypes.object,
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

export default withRouter(connect(mapStateToProps)(SurveySimulation))
