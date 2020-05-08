// @flow
import React, { Component } from 'react'
import { withRouter } from 'react-router'
import * as questionnaireActions from '../../actions/questionnaire'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import { startSmsSimulation, messageSmsSimulation } from '../../api.js'
import ChatWindow from './ChatWindow'
import DispositionChart from './DispositionChart'

type Props = {
  projectId: number,
  questionnaireId: number,
  questionnaireActions: Object
}

type ChatMessage = {
  type: string,
  body: string
}

type SmsSimulation = {
  messagesHistory: Array<ChatMessage>,
  simulationStatus: string,
  disposition: string,
  respondentId: string
}

type State = {
  smsSimulation: ?SmsSimulation
}

class SmsSimulator extends Component<Props, State> {
  state = {
    smsSimulation: null
  }

  componentWillMount() {
    const { projectId, questionnaireId } = this.props

    if (projectId && questionnaireId) {
      this.props.questionnaireActions.fetchQuestionnaireIfNeeded(projectId, questionnaireId)
      startSmsSimulation(projectId, questionnaireId).then(result => {
        this.setState({ smsSimulation: result })
      })
    }
  }

  handleMessageResult = result => {
    const { smsSimulation } = this.state
    // When the simulation expires we avoid refreshing (and so, erasing) the current state
    // So we only update the simulation status to expired
    // This allow us to handle this particular situation properly
    const newSmsSimulation = result.simulationStatus == 'expired'
      ? {
        ...smsSimulation,
        simulationStatus: 'expired'
      }
      : result
    this.setState({ smsSimulation: newSmsSimulation })
  }

  handleATMessage = message => {
    const { projectId, questionnaireId } = this.props
    const { smsSimulation } = this.state
    if (smsSimulation) {
      this.addMessage(message)
      messageSmsSimulation(projectId, questionnaireId, smsSimulation.respondentId, message.body).then(result => {
        this.handleMessageResult(result)
      })
    }
  }

  addMessage = message => {
    const { smsSimulation } = this.state
    if (smsSimulation) {
      this.setState({
        smsSimulation: {
          ...smsSimulation,
          messagesHistory: [
            ...smsSimulation.messagesHistory,
            message
          ]
        }
      })
    }
  }

  render() {
    const { smsSimulation } = this.state
    const simulationIsAvailable = smsSimulation && ['active', 'ended', 'expired'].includes(smsSimulation.simulationStatus)
    const simulationIsExpired = smsSimulation && smsSimulation.simulationStatus == 'expired'
    const simulationIsActive = smsSimulation && smsSimulation.simulationStatus == 'active'
    const renderError = msg => <div className='error'>{msg}</div>
    const header = <header>
      {
        smsSimulation
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
        smsSimulation && simulationIsAvailable
        ? <div>
          <div className='col s12 m4'>
            <DispositionChart disposition={smsSimulation.disposition} />
          </div>
          <div className='col s12 m4' />
          <div className='col s12 m4'>
            <ChatWindow messages={smsSimulation.messagesHistory} onSendMessage={this.handleATMessage} chatTitle={'SMS mode'} readOnly={!simulationIsActive} />
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
  questionnaireId: parseInt(ownProps.params.questionnaireId)
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(SmsSimulator))
