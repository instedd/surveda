import React, { Component, PropTypes } from "react"
import { bindActionCreators } from "redux"
import { connect } from "react-redux"
import * as lamejs from "lamejs"
import MediaStreamRecorder from "msr"
import * as questionnaireActions from "../../actions/questionnaire"
import * as uiActions from "../../actions/ui"

type State = {
  localURL: string,
}

class RecordAudio extends Component {
  state: State

  constructor(props) {
    super(props)
    this.state = {
      stepId: props.stepId,
      recording: false,
      serverUri: props.serverUri,
      handleRecord: props.handleRecord,
    }
  }

  onClickRecord() {
    const onMediaSuccess = (stream) => {
      const mediaRecorder = new MediaStreamRecorder(stream)
      mediaRecorder.mimeType = "audio/wav" // check this line for audio/wav
      mediaRecorder.audioChannels = 1

      mediaRecorder.ondataavailable = (blob) => {
        const mp3Data = []
        const chunks = blob
        const channels = 1 // 1 for mono or 2 for stereo
        const sampleRate = 44100 // 44.1khz (normal mp3 samplerate)
        const kbps = 128 // encode 128kbps mp3
        const mp3encoder = new lamejs.Mp3Encoder(channels, sampleRate, kbps)

        const fileReader = new FileReader()
        fileReader.addEventListener("loadend", () => {
          const samples = new Int16Array(fileReader.result)

          mp3Data.push(mp3encoder.encodeBuffer(samples))
          const mp3Tmp = mp3encoder.flush()
          mp3Data.push(mp3Tmp)

          const blob = new Blob(mp3Data, { type: "audio/mp3" })
          const file = new File([blob], `${new Date().toISOString()}_record.mp3`, {
            type: "audio/mp3",
          })
          const localURL = window.URL.createObjectURL(file)
          this.state.handleRecord([file])
          this.setState({ ...this.state, localURL: localURL, file: file })
        })
        fileReader.readAsArrayBuffer(chunks)
      }
      // mediaRecorder requires a recording lenght. 5 minutes was chosen as max length
      mediaRecorder.start(300000)

      this.setState({
        ...this.state,
        mediaRecorder: mediaRecorder,
        streamReference: stream,
        recording: true,
      })
    }
    navigator.mediaDevices.getUserMedia({ audio: true }).then(onMediaSuccess)
  }

  onClickStop() {
    this.state.mediaRecorder.stop()
    if (this.state.streamReference) {
      this.state.streamReference.getAudioTracks().forEach((track) => {
        track.stop()
      })
    }
    this.setState({ ...this.state, recording: false })
  }

  render() {
    const recordIcon = this.state.recording ? (
      <a className="record-audio-icon" onClick={() => this.onClickStop()}>
        <i className="material-icons">stop</i>
      </a>
    ) : (
      <a className="record-audio-icon" onClick={() => this.onClickRecord()}>
        <i className="material-icons">fiber_manual_record</i>
      </a>
    )

    const src = this.state.localURL || this.state.serverUri

    return (
      <div className="record-audio">
        {recordIcon}
        <audio controls key={src || "noaudio"}>
          <source src={src} type="audio/mpeg" />
        </audio>
      </div>
    )
  }
}

RecordAudio.propTypes = {
  stepId: PropTypes.string,
  questionnaireActions: PropTypes.any,
  serverUri: PropTypes.string,
  uiActions: PropTypes.any,
  handleRecord: PropTypes.func,
}

const mapStateToProps = (state) => ({
  uploadingAudio: state.ui.data.questionnaireEditor.uploadingAudio,
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch),
  uiActions: bindActionCreators(uiActions, dispatch),
})

export default connect(mapStateToProps, mapDispatchToProps)(RecordAudio)
