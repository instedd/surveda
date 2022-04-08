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

type MessagesListState = {
  toTruncate: Array<boolean>,
}

export class MessagesList extends Component<MessagesListProps, MessagesListState> {
  messagesBottomDivRef: any

  constructor(props) {
    super(props)

    this.state = {
      toTruncate: [],
    }
  }

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

  mustTruncate() {
    return this.props.truncateAt && this.props.truncateAt > 0
  }

  render() {
    let { messages } = this.props

    if (this.mustTruncate()) {
      messages = this.truncate(messages)
    }

    return (
      <div className="chat-window-body">
        <ul>
          {messages.map((message, index) => (
            <li
              key={index}
              className={`message-bubble ${message.type}-message`}
              data-index={index}
              onClick={(event) => this.onMessageClick(event)}
            >
              <div
                className="content-text"
                dangerouslySetInnerHTML={{
                  __html: linkifyStr(message.body.trim()),
                }}
              />
            </li>
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

  onMessageClick(event) {
    if (this.mustTruncate()) {
      const index = parseInt(event.currentTarget.dataset.index, 10)
      this.expandMessage(index)
    }
  }

  truncate(messages: Array<ChatMessage>) {
    const { truncateAt } = this.props
    const { toTruncate } = this.state

    return messages.map((message, index) => {
      if (toTruncate[index] !== false) {
        toTruncate[index] = message.body.length > truncateAt
      }
      return toTruncate[index]
        ? { ...message, body: `${message.body.slice(0, truncateAt)}…` }
        : message
    })
  }

  expandMessage(index: number) {
    const { toTruncate } = this.state

    if (toTruncate[index] !== false) {
      toTruncate[index] = false
      this.setState({ toTruncate })
    }
  }
}
