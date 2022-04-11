// @flow
import React, { Component } from "react"
import { translate } from "react-i18next"
import { MessagesList, ChatMessage } from "./MessagesList"

type ChatWindowProps = {
  messages: Array<ChatMessage>,
  chatTitle: string,
  onSendMessage: Function,
  readOnly: boolean,
  scrollToBottom: boolean,
}

class ChatWindow extends Component<ChatWindowProps> {
  render() {
    const { messages, onSendMessage, chatTitle, readOnly, scrollToBottom } = this.props

    return (
      <div className="chat-window quex-simulation-chat">
        <ChatTitle title={chatTitle} />
        <MessagesList messages={messages} scrollToBottom={scrollToBottom} />
        <ChatFooter onSendMessage={onSendMessage} readOnly={readOnly} />
      </div>
    )
  }
}

type ChatTitleProps = {
  title: string,
}

const ChatTitle = (props: ChatTitleProps) => {
  const { title } = props
  return <div className="chat-header">{title}</div>
}

type ChatFooterProps = {
  t: Function,
  onSendMessage: Function,
  readOnly: boolean,
}

type ChatFooterState = {
  chatInput: string,
}

const ChatFooter = translate()(
  class extends Component<ChatFooterProps, ChatFooterState> {
    constructor(props) {
      super(props)
      this.state = this.initialState
    }

    initialState = {
      chatInput: "",
    }

    sendMessage = () => {
      const { chatInput } = this.state
      const { onSendMessage } = this.props
      if (chatInput) {
        onSendMessage({ body: chatInput, type: "at" })
        this.setState(this.initialState)
      }
    }

    sendMessageIfEnterPressed = (event) => {
      if (event.key === "Enter") {
        event.preventDefault()
        this.sendMessage()
      }
    }

    render() {
      const { chatInput } = this.state
      const { t, readOnly } = this.props
      return (
        <div className="chat-window-input">
          <input
            className="chat-input"
            type="text"
            value={chatInput}
            onChange={(event) => this.setState({ chatInput: event.target.value })}
            placeholder={readOnly ? null : t("Write your message here")}
            onKeyPress={readOnly ? null : this.sendMessageIfEnterPressed}
            readOnly={readOnly}
            autoFocus
          />
          <a onClick={readOnly ? null : this.sendMessage} className="chat-button">
            <i className="material-icons">send</i>
          </a>
        </div>
      )
    }
  }
)

export default ChatWindow
