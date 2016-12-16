// @flow
import React, { Component } from 'react'
import Dropzone from 'react-dropzone'

type AudioDropzoneProps = {
  onDrop: Function,
  onDropRejected: Function
};

export class AudioDropzone extends Component {
  props: AudioDropzoneProps

  render() {
    const { onDrop, onDropRejected } = this.props

    return (
      <Dropzone className='dropfile audio' activeClassName='active' rejectClassName='rejectedfile' multiple={false} onDrop={onDrop} onDropRejected={onDropRejected} accept='audio/*' >
        <div className='drop-icon' />
        <div className='drop-text audio' />
      </Dropzone>
    )
  }
}
