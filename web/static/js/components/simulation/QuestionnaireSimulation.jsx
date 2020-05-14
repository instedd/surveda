// @flow
import React, { Component } from 'react'
import { withRouter } from 'react-router'
import * as questionnaireActions from '../../actions/questionnaire'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import { startSimulation, messageSimulation } from '../../api.js'
import ChatWindow from './ChatWindow'
import DispositionChart from './DispositionChart'
import SimulationSteps from './SimulationSteps'

type ChatMessage = {
  type: string,
  body: string
}

type Submission = {
  stepId: string,
  response: ?string
}

type Simulation = {
  messagesHistory: Array<ChatMessage>,
  submissions: Array<Submission>,
  simulationStatus: string,
  disposition: string,
  respondentId: string,
  currentStep: string,
  questionnaire: Questionnaire
}

type Props = {
  projectId: number,
  questionnaireId: number,
  mode: string,
  questionnaireActions: Object
}

type State = {
  simulation: ?Simulation
}

class QuestionnaireSimulation extends Component<Props, State> {
  state = {
    simulation: null
  }

  fetchQuestionnaireForTitle = () => {
    const { projectId, questionnaireId } = this.props
    // TODO: this component doesn't do this fetch for itself
    // It does it just because the title component above needs the questionnaire being in the redux store to render properly
    // But for some reason that component isn't able to get the projectId and questionnaireId params properly from the url
    this.props.questionnaireActions.fetchQuestionnaireIfNeeded(projectId, questionnaireId)
  }

  componentWillMount() {
    const { projectId, questionnaireId, mode } = this.props
    if (projectId && questionnaireId) {
      this.fetchQuestionnaireForTitle()
      // We only support SMS for now
      if (mode == 'sms') {
        startSimulation(projectId, questionnaireId, mode).then(result => {
          this.setState({ simulation: {
            messagesHistory: result.messagesHistory,
            submissions: result.submissions,
            simulationStatus: result.simulationStatus,
            disposition: result.disposition,
            respondentId: result.respondentId,
            currentStep: result.currentStep,
            questionnaire: result.questionnaire
          }})
        })
      }
    }
  }

  handleMessageResult = result => {
    const { simulation } = this.state
    // When the simulation expires we avoid refreshing (and so, erasing) the current state
    // So we only update the simulation status to expired
    // This allow us to handle this particular situation properly
    const newSimulation = result.simulationStatus == 'expired'
      ? {
        ...simulation,
        simulationStatus: 'expired'
      }
      : {
        ...simulation,
        messagesHistory: result.messagesHistory,
        submissions: result.submissions,
        simulationStatus: result.simulationStatus,
        disposition: result.disposition,
        currentStep: result.currentStep
      }
    this.setState({ simulation: newSimulation })
  }

  handleATMessage = message => {
    const { projectId, questionnaireId } = this.props
    const { simulation } = this.state
    if (simulation) {
      this.addMessage(message)
      messageSimulation(projectId, questionnaireId, simulation.respondentId, message.body).then(result => {
        this.handleMessageResult(result)
      })
    }
  }

  addMessage = message => {
    const { simulation } = this.state
    if (simulation) {
      this.setState({
        simulation: {
          ...simulation,
          messagesHistory: [
            ...simulation.messagesHistory,
            message
          ]
        }
      })
    }
  }

  render() {
    const { simulation } = this.state
    const simulationIsAvailable = simulation && ['active', 'ended', 'expired'].includes(simulation.simulationStatus)
    const simulationIsExpired = simulation && simulation.simulationStatus == 'expired'
    const simulationIsActive = simulation && simulation.simulationStatus == 'active'
    const renderError = msg => <div className='error'>{msg}</div>
    const header = <header>
      {
        simulation
        ? simulationIsAvailable
          ? simulationIsExpired
            ? renderError('This simulation is expired. Please refresh to start a new one')
            : null
          : renderError('This simulation isn\'t available. Please refresh')
        : 'Loading'
      }
    </header>
    const main = <main>
      {
        simulation && simulationIsAvailable
        ? <div>
          <div className='col s12 m4'>
            <DispositionChart disposition={simulation.disposition} />
          </div>
          <div className='col s12 m4'>
            <SimulationSteps steps={simulation.questionnaire.steps}
              currentStepId={simulation.currentStep}
              submissions={simulation.submissions}
            />
          </div>
          <div className='col s12 m4'>
            <ChatWindow messages={simulation.messagesHistory} onSendMessage={this.handleATMessage} chatTitle={'SMS mode'} readOnly={!simulationIsActive} />
          </div>
        </div>
        : null
      }
    </main>

    return <div className='simulator-container'>
      {header}
      {main}
    </div>
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: parseInt(ownProps.params.projectId),
  questionnaireId: parseInt(ownProps.params.questionnaireId),
  mode: ownProps.params.mode
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(QuestionnaireSimulation))
