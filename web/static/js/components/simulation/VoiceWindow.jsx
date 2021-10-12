// @flow
import React, { Component } from 'react'

type Message = {
  body: string,
  type: string
}

type VoiceWindowProps = {
  simulation: any,
  voiceTitle: string,
  onSendMessage: (Message) => void,
  onCloseSimulation: () => void,
  readOnly: boolean
}

class VoiceWindow extends Component<VoiceWindowProps> {
  message: string
  timer: TimeoutID

  componentDidMount() {
    this.message = ''
  }

  entered(character: string): void {
    if (this.timer) {
      clearTimeout(this.timer)
    }
    this.message += character

    this.timer = setTimeout(() => {
      this.props.onSendMessage({ body: this.message, type: 'at' })
      this.message = ''
    }, 2000)
  }

  currentPrompt(): string {
    const { simulation } = this.props
    const { currentStep, questionnaire } = simulation
    const step = questionnaire.steps.find(step => step.id == currentStep)

    if (step) {
      const ivr = step.prompt[questionnaire.defaultLanguage].ivr
      switch (ivr.audioSource) {
        case "tts":
          return step.prompt[questionnaire.defaultLanguage].ivr.text
        // TODO: support other types
      }
    }
    return ""
  }

  render() {
    const { voiceTitle, readOnly, onCloseSimulation } = this.props

    return <div className='voice-window quex-simulation-voice'>
      <div className='voice-header'>{voiceTitle}</div>
      <div className='voice-question'>{this.currentPrompt()}</div>
      <div className='voice-buttons'>
        <div onClick={() => this.entered('1')} className='voice-button'>1</div>
        <div onClick={() => this.entered('2')} className='voice-button'>2</div>
        <div onClick={() => this.entered('3')} className='voice-button'>3</div>
        <div onClick={() => this.entered('4')} className='voice-button'>4</div>
        <div onClick={() => this.entered('5')} className='voice-button'>5</div>
        <div onClick={() => this.entered('6')} className='voice-button'>6</div>
        <div onClick={() => this.entered('7')} className='voice-button'>7</div>
        <div onClick={() => this.entered('8')} className='voice-button'>8</div>
        <div onClick={() => this.entered('9')} className='voice-button'>9</div>
        <div onClick={() => this.entered('*')} className='voice-button'>*</div>
        <div onClick={() => this.entered('0')} className='voice-button'>0</div>
        <div onClick={() => this.entered('#')} className='voice-button'>#</div>
        <div onClick={() => onCloseSimulation()} className='voice-button voice-button-end-call'>
          <i className='material-icons'>call_end</i>
        </div>
      </div>
    </div>
  }
}

export default VoiceWindow
