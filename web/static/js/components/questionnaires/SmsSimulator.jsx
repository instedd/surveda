import React, { Component, PropTypes } from 'react'
import { withRouter } from 'react-router'
import * as questionnaireActions from '../../actions/questionnaire'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import { startSmsSimulation, messageSmsSimulation } from '../../api.js'

class SmsSimulator extends Component {

  state = {
    messages: [],
    respondentId: ''
  }

  componentWillMount() {
    const { projectId, questionnaireId } = this.props

    if (projectId && questionnaireId) {
      this.props.questionnaireActions.fetchQuestionnaireIfNeeded(projectId, questionnaireId)
      startSmsSimulation(projectId, questionnaireId).then(result => {
        this.setState({ messages: result.messgesHistory, respondentId: result.respondentId })
      })
    }
  }

  handleATMessage = message => {
    const { projectId, questionnaireId } = this.props
    const { respondentId } = this.state

    this.addMessage(message)
    messageSmsSimulation(projectId, questionnaireId, respondentId, message.body).then(result => {
      this.setState({ messages: result.messgesHistory })
    })
  }

  addMessage = msg => {
    this.setState({ messages: [...this.state.messages, msg] })
  }

  render() {
    const { messages } = this.state
    if (messages.length) {
      return <div className='simulator-container'>
        <div className='col s4 offset-s8'>
          <ChatWindow messages={messages} onSendMessage={this.handleATMessage} chatTitle={'SMS mode'} />
        </div>
      </div>
    } else {
      return <div>Loading</div>
    }
  }
}

SmsSimulator.propTypes = {
  projectId: PropTypes.number,
  questionnaireId: PropTypes.number,
  questionnaireActions: PropTypes.object
}

class ChatWindow extends Component {

  render() {
    const { messages, onSendMessage, chatTitle } = this.props

    return (
      <div className='chat-window'>
        <ChatTitle title={chatTitle} />
        <MessagesList messages={messages} />
        <ChatFooter onSendMessage={onSendMessage} />
      </div>
    )
  }
}

ChatWindow.propTypes = {
  messages: PropTypes.array.isRequired,
  chatTitle: PropTypes.string.isRequired,
  onSendMessage: PropTypes.func.isRequired
}

const ChatTitle = props => {
  const { title } = props
  return (
    <div className='chat-header'>{title}</div>
  )
}

ChatTitle.propTypes = {
  title: PropTypes.string.isRequired
}

const MessageBulk = props => {
  const { messages } = props
  const ATMessage = messages[0].type === 'at'
  return (
    <div className={'message-bubble'}>
      {messages.map((message, ix) =>
        <li key={ix} className={ATMessage ? 'at-message' : 'ao-message'}>
          <div className='content-text'>
            {message.body.trim()}
          </div>
        </li>
      )}
    </div>
  )
}

MessageBulk.propTypes = {
  messages: PropTypes.array.isRequired
}

class MessagesList extends Component {
  scrollToBottom = () => {
    window.setTimeout(() => this._messagesBottomDiv.scrollIntoView({ behavior: 'smooth' }), 0)
  }

  componentDidMount() {
    this.scrollToBottom()
  }

  componentDidUpdate() {
    this.scrollToBottom()
  }

  render() {
    const groupBy = (elems, func) => {
      const lastElem = (collection) => (collection[collection.length - 1])

      return elems.reduce(function(groups, elem) {
        const lastGroup = lastElem(groups)
        if (groups.length == 0 || func(lastElem(lastGroup)) != func(elem)) {
          groups.push([elem])
        } else {
          lastGroup.push(elem)
        }
        return groups
      }, [])
    }

    const { messages } = this.props
    const groupedMessages = groupBy(messages, (message) => (message.type))

    return (
      <div className='chat-window-body'>
        <ul>
          {groupedMessages.map((messages, ix) =>
            <MessageBulk
              key={`msg-bulk-${ix}`}
              messages={messages}
            />
          )}
        </ul>
        <div style={{ float: 'left', clear: 'both' }} ref={el => { this._messagesBottomDiv = el }} />
      </div>
    )
  }
}

MessagesList.propTypes = {
  messages: PropTypes.array.isRequired
}

class ChatFooter extends Component {
  constructor(props) {
    super(props)

    this.initialState = {
      body: '',
      type: 'at'
    }

    this.state = this.initialState
  }
  handleChange = event => {
    const { name, value } = event.target
    this.setState({
      [name]: value
    })
  }

  sendMessage = () => {
    this.props.onSendMessage(this.state)
    this.setState(this.initialState)
  }

  sendMessageIfEnterPressed = (event) => {
    if (event.key === 'Enter') {
      event.preventDefault()
      this.sendMessage()
    }
  }

  render() {
    const { body } = this.state
    return (
      <div className='chat-window-input'>
        <input className='chat-input'
          type='text'
          name='body'
          value={body}
          onChange={this.handleChange}
          placeholder='Write your message here'
          onKeyPress={this.sendMessageIfEnterPressed}
        />
        <a onClick={this.sendMessage} className='chat-button'>
          <i className='material-icons'>send</i>
        </a>
      </div>
    )
  }
}

ChatFooter.propTypes = {
  onSendMessage: PropTypes.func.isRequired
}
const mapStateToProps = (state, ownProps) => ({
  projectId: parseInt(ownProps.params.projectId),
  questionnaireId: parseInt(ownProps.params.questionnaireId)
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(SmsSimulator))
