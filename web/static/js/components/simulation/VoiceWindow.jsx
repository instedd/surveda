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
  playPromise: Promise<any>

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

      if (this.playPromise) {
        this.playPromise
          .then(() => this.playIVR(ivr))
          .catch(() => { /* audio prompt failed to load */ })
      } else {
        // first audio prompt and/or older browser didn't return a promise on play
        this.playIVR(ivr)
      }
    }
  }

  playIVR(ivr) {
    // we may be interrupting an audio prompt here, so we stop any playing
    // audio, before skipping to the next one:
    this.audio.pause()

    // play the IVR prompt, continuing to the next one when finished:
    this.audio.src = audioURL(ivr)
    this.audio.onended = () => { this.play() }
    this.playPromise = this.audio.play()
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

  hangUp(): void {
    if (this.props.readOnly) return
    if (this.messageTimer) clearTimeout(this.messageTimer)
    this.props.onSendMessage({ body: 'stop', type: 'at' })
  }

  render() {
    const { voiceTitle, onCloseSimulation } = this.props

    return <div className='voice-window quex-simulation-voice'>
      <div className='voice-header'>{voiceTitle}</div>
      <div className='voice-question'>{this.state.currentPrompt}</div>
      <div className='voice-buttons'>
        <div onClick={() => this.entered('1')} className='waves-effect waves-circle voice-button'>1</div>
        <div onClick={() => this.entered('2')} className='waves-effect waves-circle voice-button'>2</div>
        <div onClick={() => this.entered('3')} className='waves-effect waves-circle voice-button'>3</div>
        <div onClick={() => this.entered('4')} className='waves-effect waves-circle voice-button'>4</div>
        <div onClick={() => this.entered('5')} className='waves-effect waves-circle voice-button'>5</div>
        <div onClick={() => this.entered('6')} className='waves-effect waves-circle voice-button'>6</div>
        <div onClick={() => this.entered('7')} className='waves-effect waves-circle voice-button'>7</div>
        <div onClick={() => this.entered('8')} className='waves-effect waves-circle voice-button'>8</div>
        <div onClick={() => this.entered('9')} className='waves-effect waves-circle voice-button'>9</div>
        <div onClick={() => this.entered('*')} className='waves-effect waves-circle voice-button'>*</div>
        <div onClick={() => this.entered('0')} className='waves-effect waves-circle voice-button'>0</div>
        <div onClick={() => this.entered('#')} className='waves-effect waves-circle voice-button'>#</div>
        <div onClick={() => this.hangUp()} className='waves-effect waves-circle voice-button voice-button-end-call red'>
          <i className='material-icons'>call_end</i>
        </div>
      </div>

      <audio ref={audio => { if (audio) this.audio = audio }} preload />
    </div>
  }
})

export default VoiceWindow
