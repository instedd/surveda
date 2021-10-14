// @flow
import React, { Component } from 'react'

type Message = {
  body: string,
  type: string
}

type IVR = {
  text: string,
  audioSource: string,
  audioId: string
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

  previousAudioURL: ?string
  audio: ?HTMLAudioElement

  componentDidMount() {
    this.message = ''
    this.play()
  }

  componentDidUpdate() {
    this.play()
  }

  play() {
    if (this.audio && this.previousAudioURL != this.audio.src) {
      this.previousAudioURL = this.audio.src
      this.audio.play()
    }
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

  currentIVR(): ?IVR {
    const { simulation } = this.props
    const { currentStep, questionnaire } = simulation
    const step = questionnaire.steps.find(step => step.id == currentStep)
    if (step) {
      return step.prompt[questionnaire.defaultLanguage].ivr
    }
  }

  currentPrompt(): string {
    const ivr = this.currentIVR()
    return ivr ? ivr.text : ''
  }

  currentAudioURL(): ?string {
    const ivr = this.currentIVR()

    if (ivr) {
      if (ivr.audioSource == 'tts') {
        return `/api/v1/audios/tts?text=${encodeURIComponent(ivr.text)}`
      } else {
        return `/api/v1/audios/${ivr.audioId}`
      }
    }
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

      {this.renderAudioElement()}
    </div>
  }

  renderAudioElement() {
    const url = this.currentAudioURL()
    if (url) {
      return <audio ref={audio => { this.audio = audio }} preload src={url}></audio>
    }
  }
}

export default VoiceWindow
