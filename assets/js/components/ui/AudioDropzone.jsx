// @flow
import React, { Component } from "react"
import Dropzone from "react-dropzone"

type Props = {
  onDrop: Function,
  onDropRejected: Function,
  error: boolean,
}

export class AudioDropzone extends Component<Props> {
  render() {
    const { onDrop, onDropRejected, error } = this.props

    // Dropzone may have filtered out an unknown file format, in that case the
    // files array will be empty, and we should reject instead of accepting the
    // drop.
    function verifyDrop(files) {
      if (files.length === 0) {
        onDropRejected()
      } else {
        onDrop(files)
      }
    }

    let className = "dropfile audio"
    if (error) className = `${className} error`

    return (
      <Dropzone
        className={className}
        activeClassName="active"
        rejectClassName="rejectedfile"
        multiple={false}
        onDrop={verifyDrop}
        onDropRejected={onDropRejected}
        accept="audio/*, video/*"
      >
        <div className="drop-icon" />
        <div className="drop-text audio" />
      </Dropzone>
    )
  }
}
