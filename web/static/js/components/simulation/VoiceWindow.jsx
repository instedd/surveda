// @flow
import React, { Component } from 'react'
import { translate } from 'react-i18next'

type Message = {
  body: string,
  type: string
}

export type IVRPrompt = {
  text: string,
  audioSource: string,
  audioId: string
}

type VoiceWindowProps = {
  prompts: Array<IVRPrompt>,
  voiceTitle: string,
  onSendMessage: Message => void,
  onCloseSimulation: () => void,
  readOnly: boolean
}

type VoiceWindowState = {
  currentPrompt: string
}

function audioURL(ivr: IVRPrompt): string {
  if (!ivr) {
    return ''
  }
  if (ivr.audioSource == 'tts') {
    return `/api/v1/audios/tts?text=${encodeURIComponent(ivr.text)}`
  }
  return `/api/v1/audios/${ivr.audioId}`
}

const VoiceWindow = translate()(class extends Component<VoiceWindowProps, VoiceWindowState> {
  audio: HTMLAudioElement

  message: string
  messageTimer: TimeoutID

  constructor(props) {
    super(props)
    this.state = { currentPrompt: '' }
  }

  componentDidMount() {
    this.message = ''
    this.play()
  }

  componentDidUpdate(prevProps) {
    if (prevProps.prompts !== this.props.prompts) {
      this.play()
    }
  }

  play() {
    const ivr = this.props.prompts.shift()
    if (ivr) {
      this.setState({ currentPrompt: ivr.text })
      this.audio.pause()
      this.audio.src = audioURL(ivr)
      this.audio.onended = () => { this.play() }
      this.audio.play()
    }
  }

  entered(character: string): void {
    if (this.props.readOnly) return
    if (this.messageTimer) clearTimeout(this.messageTimer)
    this.message += character

    this.messageTimer = setTimeout(() => {
      if (this.props.readOnly) return

      this.props.onSendMessage({ body: this.message, type: 'at' })
      this.message = ''
    }, 2000)
  }

  render() {
    const { voiceTitle, onCloseSimulation } = this.props

    return <div className='voice-window quex-simulation-voice'>
      <div className='voice-header'>{voiceTitle}</div>
      <div className='voice-question'>{this.state.currentPrompt}</div>
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

      <audio ref={audio => { if (audio) this.audio = audio }} preload />
    </div>
  }
})

export default VoiceWindow
