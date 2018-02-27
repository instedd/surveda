import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as lamejs from 'lamejs'
import MediaStreamRecorder from 'msr'
import { createAudio } from '../../api.js'
import * as questionnaireActions from '../../actions/questionnaire'
import * as uiActions from '../../actions/ui'

type State = {
};

class RecordAudio extends Component {
  state: State

  constructor(props) {
    super(props)
    this.state = {stepId: props.stepId}
  }

  onClickRecord() {
    const onMediaSuccess = (stream) => {
      const mediaRecorder = new MediaStreamRecorder(stream)
      mediaRecorder.mimeType = 'audio/wav' // check this line for audio/wav
      mediaRecorder.audioChannels = 1

      mediaRecorder.ondataavailable = (blob) => {
        const mp3Data = []
        const chunks = blob
        const channels = 1 // 1 for mono or 2 for stereo
        const sampleRate = 44100 // 44.1khz (normal mp3 samplerate)
        const kbps = 128 // encode 128kbps mp3
        // const sampleBlockSize = 1152
        const mp3encoder = new lamejs.Mp3Encoder(channels, sampleRate, kbps)

        const fileReader = new FileReader()
        fileReader.addEventListener('loadend', () => {
          const samples = new Int16Array(fileReader.result)

          mp3Data.push(mp3encoder.encodeBuffer(samples))
          const mp3Tmp = mp3encoder.flush()
          mp3Data.push(mp3Tmp)

          const blob = new Blob(mp3Data, {type: 'audio/mp3'})
          const file = new File([blob], 'record_audio.mp3', {type: 'audio/mp3'})
          const audioURL = window.URL.createObjectURL(file)
          this.setState({...this.state, audioURL: audioURL, file: file})
        })
        fileReader.readAsArrayBuffer(chunks)
      }
      mediaRecorder.start(300000)

      this.setState({...this.state, mediaRecorder: mediaRecorder})
    }
    navigator.mediaDevices.getUserMedia({audio: true}).then(onMediaSuccess)
  }

  onClickStop() {
    this.state.mediaRecorder.stop()
  }

  confirm() {
    const file = this.state.file
    this.props.uiActions.uploadAudio(this.state.stepId)
    createAudio([file]).then(response => {
      this.props.questionnaireActions.changeStepAudioIdIvr(this.state.stepId, response.result)
      this.props.uiActions.finishAudioUpload()
    })
  }

  render() {
    return (
      <div>
        <section className='main-controls'>
          <audio controls src={this.state.audioURL || ''} />
          <div id='buttons'>
            <button onClick={() => this.onClickRecord()}>Record</button>
            <button onClick={() => this.onClickStop()}>Stop</button>
            <button onClick={() => this.confirm()}>Confirm</button>
          </div>
        </section>
      </div>
    )
  }
}

RecordAudio.propTypes = {
  stepId: PropTypes.string,
  questionnaireActions: PropTypes.any,
  uiActions: PropTypes.any
}

const mapStateToProps = (state) => ({
  uploadingAudio: state.ui.data.questionnaireEditor.uploadingAudio
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch),
  uiActions: bindActionCreators(uiActions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(RecordAudio)
