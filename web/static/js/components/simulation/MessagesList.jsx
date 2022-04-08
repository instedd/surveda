import React, { Component } from "react"
import linkifyStr from "linkifyjs/string"

export type ChatMessage = {
  type: string,
  body: string,
}

type MessagesListProps = {
  messages: Array<ChatMessage>,
  scrollToBottom: boolean,
  truncateAt: ?number,
}

type MessageProps = {
  message: ChatMessage,
  truncateAt: ?number,
}

type MessageState = {
  truncated: boolean,
}

class Message extends Component<MessageProps, MessageState> {
  constructor(props) {
    super(props)

    this.state = {
      truncated: props.truncateAt && props.message.body.length > props.truncateAt,
    }
  }

  render() {
    const { message } = this.props
    const body = this.truncate(message.body.trim())

    return (
      <li className={`message-bubble ${message.type}-message`} onClick={() => this.expand()}>
        <div className="content-text" dangerouslySetInnerHTML={{ __html: linkifyStr(body) }} />
      </li>
    )
  }

  truncate(body) {
    return this.state.truncated === true ? `${body.slice(0, this.props.truncateAt)}…` : body
  }

  expand() {
    if (this.state.truncated) {
      this.setState({ truncated: false })
    }
  }
}

export class MessagesList extends Component<MessagesListProps> {
  messagesBottomDivRef: any

  scrollToBottom = () => {
    if (this.props.scrollToBottom) {
      window.setTimeout(() => {
        this.messagesBottomDivRef.scrollIntoView({ behavior: "smooth" })
      }, 0)
    }
  }

  componentDidMount() {
    this.scrollToBottom()
  }

  componentDidUpdate(prevProps) {
    // only autoscroll to bottom if the list of messages changed (we assume the
    // list can only grow or shrink, not changed in place):
    if (prevProps.messages.length !== this.props.messages.length) {
      this.scrollToBottom()
    }
  }

  render() {
    let { messages } = this.props

    return (
      <div className="chat-window-body">
        <ul>
          {messages.map((message, index) => (
            <Message message={message} key={index} truncateAt={this.props.truncateAt} />
          ))}
        </ul>
        <div
          style={{ float: "left", clear: "both" }}
          ref={(el) => {
            this.messagesBottomDivRef = el
          }}
        />
      </div>
    )
  }
}
