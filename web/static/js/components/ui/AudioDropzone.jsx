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

    let className = "dropfile audio"
    if (error) className = `${className} error`

    return (
      <Dropzone
        className={className}
        activeClassName="active"
        rejectClassName="rejectedfile"
        multiple={false}
        onDrop={onDrop}
        onDropRejected={onDropRejected}
        accept="audio/*"
      >
        <div className="drop-icon" />
        <div className="drop-text audio" />
      </Dropzone>
    )
  }
}
