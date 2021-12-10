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
  spectrum: VoiceSpectrum

  message: string
  messageTimer: TimeoutID

  constructor(props) {
    super(props)
    this.state = { currentPrompt: '' }
    this.spectrum = new VoiceSpectrum()
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

  componentWillUnmount() {
    if (this.spectrum) {
      this.spectrum.stop()
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
    } else {
      this.spectrum.stop()
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
    this.spectrum.start(this.audio)
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
    const { voiceTitle } = this.props

    return <div className='voice-window quex-simulation-voice'>
      <div className='voice-header'>{voiceTitle}</div>

      <div className='voice-spectrum'>
        <canvas ref={canvas => this.spectrum.setCanvas(canvas)} className='voice-spectrum-bands' />
      </div>

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

      <audio ref={audio => { this.setAudio(audio) }} preload />
    </div>
  }

  setAudio(element) {
    if (!element) return
    this.audio = element
  }
})

class VoiceSpectrum {
  audioContext: AudioContext
  audioAnalyser: AnalyserNode
  amplitudeData: Uint8Array
  canvas: HTMLCanvasElement
  context: CanvasRenderingContext2D
  sizes: { width: number, height: number, halfHeight: number }
  playing: boolean

  constructor() {
    this.audioContext = new AudioContext()
    this.audioAnalyser = this.audioContext.createAnalyser()
    this.audioAnalyser.fftSize = 256
    this.amplitudeData = new Uint8Array(0)
    this.playing = false
  }

  setCanvas(canvas) {
    if (canvas) {
      this.canvas = canvas
      this.context = canvas.getContext('2d')

      // fix canvas' size for HiDPI from its CSS size (DPI=1)
      const ratio = window.devicePixelRatio || 1
      const width = canvas.offsetWidth
      const height = canvas.offsetHeight
      canvas.width = canvas.offsetWidth * ratio
      canvas.height = canvas.offsetHeight * ratio
      this.context.scale(ratio, ratio)
      this.sizes = { width, height, halfHeight: height / 2 }
    }
  }

  start(audio) {
    // <audio> element -> AudioSource -> AudioAnalyser -> destination
    this.audioContext.createMediaElementSource(audio).connect(this.audioAnalyser)
    this.audioAnalyser.connect(this.audioContext.destination)

    this.amplitudeData = new Uint8Array(this.audioAnalyser.frequencyBinCount)
    this.playing = true
    requestAnimationFrame(() => this.run())
  }

  run() {
    if (this.playing) {
      this.audioAnalyser.getByteFrequencyData(this.amplitudeData)
      this.updateCanvas()
      requestAnimationFrame(() => this.run())
    }
  }

  stop() {
    requestAnimationFrame(() => {
      this.amplitudeData.fill(0)
      this.updateCanvas()
      this.playing = false
    })
  }

  updateCanvas() {
    if (!this.canvas) return

    const ctx = this.context
    const bufferLength = this.amplitudeData.length
    const { width, height, halfHeight } = this.sizes
    const barGap = 3
    const barWidth = 4
    const radii = 2
    let x = barGap

    ctx.clearRect(0, 0, width, height)
    ctx.fillStyle = 'rgb(255, 255, 255)'

    // only use some entries in the fft, to increase diversity and movement
    for (let i = 5; i < bufferLength; i += 5) {
      const v = this.amplitudeData[i] / 256
      const y = parseInt(v * halfHeight)

      this._roundRect(x, halfHeight - y, barWidth, y * 2, radii)
      ctx.fill()

      x += barWidth + barGap
      if (x > width) break
    }
  }

  _roundRect(x, y, width, height, radii) {
    const ctx = this.context
    if (width < 2 * radii) radii = width / 2
    if (height < 2 * radii) radii = height / 2
    ctx.beginPath()
    ctx.moveTo(x + radii, y)
    ctx.arcTo(x + width, y, x + width, y + height, radii)
    ctx.arcTo(x + width, y + height, x, y + height, radii)
    ctx.arcTo(x, y + height, x, y, radii)
    ctx.arcTo(x, y, x + width, y, radii)
    ctx.closePath()
  }
}

export default VoiceWindow
