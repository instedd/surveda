// @flow
import React, { Component } from 'react'
import { translate } from 'react-i18next'

type ChatMessage = {
  type: string,
  body: string
}

type ChatWindowProps = {
  messages: Array<ChatMessage>,
  chatTitle: string,
  onSendMessage: Function
}

class ChatWindow extends Component<ChatWindowProps> {
  render() {
    const { messages, onSendMessage, chatTitle } = this.props

    return <div className='chat-window'>
      <ChatTitle title={chatTitle} />
      <MessagesList messages={messages} />
      <ChatFooter onSendMessage={onSendMessage} />
    </div>
  }
}

type ChatTitleProps = {
  title: string
}

const ChatTitle = (props: ChatTitleProps) => {
  const { title } = props
  return (
    <div className='chat-header'>{title}</div>
  )
}

type MessageBulkProps = {
  messages: Array<ChatMessage>
}

const MessageBulk = (props: MessageBulkProps) => {
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

type MessagesListProps = {
  messages: Array<ChatMessage>
}

class MessagesList extends Component<MessagesListProps> {
  messagesBottomDivRef: any

  scrollToBottom = () => {
    window.setTimeout(() => this.messagesBottomDivRef.scrollIntoView({ behavior: 'smooth' }), 0)
  }

  componentDidMount() {
    this.scrollToBottom()
  }

  componentDidUpdate() {
    this.scrollToBottom()
  }

  render() {
    const groupBy = (elems, func) => {
      const lastElem = (collection: Array<any>) => (collection[collection.length - 1])

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
    const groupedMessages = groupBy(messages, (message: ChatMessage) => message.type)

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
        <div style={{ float: 'left', clear: 'both' }} ref={el => { this.messagesBottomDivRef = el }} />
      </div>
    )
  }
}

type ChatFooterProps = {
  t: Function,
  onSendMessage: Function
}

type ChatFooterState = {
  chatInput: string
}

const ChatFooter = translate()(class extends Component<ChatFooterProps, ChatFooterState> {
  constructor(props) {
    super(props)
    this.state = this.initialState
  }

  initialState = {
    chatInput: ''
  }

  sendMessage = () => {
    const { chatInput } = this.state
    const { onSendMessage } = this.props
    onSendMessage({ body: chatInput, type: 'at' })
    this.setState(this.initialState)
  }

  sendMessageIfEnterPressed = (event) => {
    if (event.key === 'Enter') {
      event.preventDefault()
      this.sendMessage()
    }
  }

  render() {
    const { chatInput } = this.state
    const { t } = this.props
    return (
      <div className='chat-window-input'>
        <input className='chat-input'
          type='text'
          value={chatInput}
          onChange={event => this.setState({ chatInput: event.target.value })}
          placeholder={t('Write your message here')}
          onKeyPress={this.sendMessageIfEnterPressed}
        />
        <a onClick={this.sendMessage} className='chat-button'>
          <i className='material-icons'>send</i>
        </a>
      </div>
    )
  }
})

export default ChatWindow
