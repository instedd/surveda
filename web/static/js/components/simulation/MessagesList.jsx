import React, { Component } from 'react'
import linkifyStr from 'linkifyjs/string'

export type ChatMessage = {
  type: string,
  body: string
}

type MessageBulkProps = {
  messages: Array<ChatMessage>
}

type MessagesListProps = {
  messages: Array<ChatMessage>,
  scrollToBottom: boolean
}

function MessageBulk(props: MessageBulkProps) {
  const { messages } = props
  const ATMessage = messages[0].type === 'at'

  return (
    <div className={'message-bubble'}>
      {messages.map((message, ix) =>
        <li key={ix} className={ATMessage ? 'at-message' : 'ao-message'}>
          <div className='content-text' dangerouslySetInnerHTML={{__html: linkifyStr(message.body.trim())}} />
        </li>
      )}
    </div>
  )
}

export class MessagesList extends Component<MessagesListProps> {
  messagesBottomDivRef: any

  scrollToBottom = () => {
    if (this.props.scrollToBottom) {
      window.setTimeout(() => {
        this.messagesBottomDivRef.scrollIntoView({ behavior: 'smooth' })
      }, 0)
    }
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
