// @flow
import React, { Component } from "react"
import { translate } from "react-i18next"
import { MessagesList, ChatMessage } from "./MessagesList"

type Message = {
  body: string,
  type: string,
}

export type IVRPrompt = {
  text: string,
  audioSource: string,
  audioId: string,
}

type VoiceWindowProps = {
  messages: Array<ChatMessage>,
  prompts: Array<IVRPrompt>,
  voiceTitle: string,
  onSendMessage: (Message | string) => void,
  readOnly: boolean,
}

function audioURL(ivr: IVRPrompt): string {
  if (!ivr) {
    return ""
  }
  if (ivr.audioSource == "tts") {
    return `/api/v1/audios/tts?text=${encodeURIComponent(ivr.text)}`
  }
  return `/api/v1/audios/${ivr.audioId}`
}

const VoiceWindow = translate()(
  class extends Component<VoiceWindowProps> {
    audio: HTMLAudioElement
    playPromise: Promise<any>
    spectrum: VoiceSpectrum

    message: string
    messageTimer: ?TimeoutID
    answerTimeout: ?TimeoutID

    constructor(props) {
      super(props)
      this.spectrum = new VoiceSpectrum()
    }

    componentDidMount() {
      this.message = ""
      this.play()
    }

    componentDidUpdate(prevProps) {
      if (prevProps.prompts !== this.props.prompts) {
        this.play()
      }
    }

    componentWillUnmount() {
      if (this.spectrum) this.spectrum.stop()
      this.stopSimulation()
    }

    // Plays the current prompts in the order the simulator tells us to.
    // Eventually starts waiting for an answer message to send.
    play() {
      const ivr = this.props.prompts.shift()
      if (ivr) {
        if (this.playPromise) {
          this.playPromise
            .then(() => this.playIVR(ivr))
            .catch(() => {
              /* audio prompt failed to load */
            })
        } else {
          // first audio prompt and/or older browser didn't return a promise on play
          this.playIVR(ivr)
        }
      } else {
        this.spectrum.stop()

        if (!this.props.readOnly) {
          this.initAnswerTimeout()
        }
      }
    }

    // Plays a single IVR prompt. Eventually calls `play()` to skip to the next
    // audio or start waiting for an answer.
    playIVR(ivr) {
      // we may be interrupting an audio prompt here, so we stop any playing
      // audio, before skipping to the next one:
      this.audio.pause()

      // play the IVR prompt, continuing to the next one when finished:
      this.audio.src = audioURL(ivr)
      this.audio.onended = () => {
        this.play()
      }
      this.playPromise = this.audio.play()

      this.spectrum.start(this.audio)
    }

    // Starts a timer that will call `noAnswer()`. Must be cancelled if a digit
    // is pressed.
    initAnswerTimeout(): void {
      this.cancelAnswerTimeout()
      this.answerTimeout = setTimeout(() => this.noAnswer(), 5000)
    }

    cancelAnswerTimeout(): void {
      if (this.answerTimeout) {
        clearTimeout(this.answerTimeout)
        this.answerTimeout = null
      }
    }

    // Appends the typed digit to the current message, then starts a 2s timer to
    // send the message, unless another digit is pressed.
    entered(character: string): void {
      if (this.props.readOnly) return
      this.cancelAnswerTimeout()
      this.cancelMessageTimer()

      this.message += character

      this.messageTimer = setTimeout(() => {
        if (this.props.readOnly) return

        this.props.onSendMessage({ body: this.message, type: "at" })
        this.message = ""
      }, 2000)
    }

    cancelMessageTimer(): void {
      if (this.messageTimer) {
        clearTimeout(this.messageTimer)
        this.messageTimer = null
      }
    }

    stopSimulation(): void {
      this.audio.pause()
      this.cancelAnswerTimeout()
      this.cancelMessageTimer()
    }

    // Simulates a phone hangup by sending a STOP message. This is kinda
    // hackish, we could probably send a proper hangup message that would be
    // properly handled by the simulator.
    hangUp(): void {
      this.stopSimulation()

      if (!this.props.readOnly) {
        this.props.onSendMessage({ body: "stop", type: "at" })
      }
    }

    // Reports a timeout while waiting for an answer to the simulator.
    noAnswer(): void {
      this.stopSimulation()

      if (!this.props.readOnly) {
        this.props.onSendMessage("timeout")
      }
    }

    render() {
      const { voiceTitle, messages } = this.props
      const buttons = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#"]

      return (
        <div className="voice-window quex-simulation-voice">
          <div className="voice-header">{voiceTitle}</div>
          <div className="voice-spectrum">
            <canvas
              ref={(canvas) => this.spectrum.setCanvas(canvas)}
              className="voice-spectrum-bands"
            />
          </div>
          <MessagesList messages={messages} truncateAt={140} scrollToBottom />

          <div className="voice-keypad">
            {buttons.map((value) => (
              <div
                key={`keypad-button-${value}`}
                onClick={() => this.entered(value)}
                className="waves-effect waves-circle voice-button"
              >
                {value}
              </div>
            ))}

            <div
              onClick={() => this.hangUp()}
              className="waves-effect waves-circle voice-button voice-button-end-call red"
            >
              <i className="material-icons">call_end</i>
            </div>
          </div>

          <audio ref={(audio) => this.setAudio(audio)} preload />
        </div>
      )
    }

    setAudio(element) {
      if (!element) return
      this.audio = element
    }
  }
)

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
      this.context = canvas.getContext("2d")

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
    this.restart()
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

  // We need a restart method, because using `start(audio)` on the same audio raises:
  // Uncaught InvalidStateError: Failed to execute 'createMediaElementSource' on 'AudioContext':
  // HTMLMediaElement already connected previously to a different MediaElementSourceNode."
  // https://bugs.chromium.org/p/chromium/issues/detail?id=429204
  // https://bugs.chromium.org/p/chromium/issues/detail?id=851310
  // https://stackoverflow.com/questions/38460984/problems-disconnecting-nodes-with-audiocontext-web-audio-api
  restart() {
    this.amplitudeData = new Uint8Array(this.audioAnalyser.frequencyBinCount)
    this.playing = true
    requestAnimationFrame(() => this.run())
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
    ctx.fillStyle = "rgb(255, 255, 255)"

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
