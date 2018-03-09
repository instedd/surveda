import React, { PropTypes } from 'react'
import Dropzone from 'react-dropzone'
import { Preloader } from 'react-materialize'

export const RespondentsDropzone = ({ survey, uploading, onDrop, onDropRejected }) => {
  let className = 'drop-text csv'
  if (uploading) className += ' uploading'

  let icon = null
  if (uploading) {
    icon = (
      <div className='drop-uploading'>
        <div className='preloader-wrapper active center'>
          <Preloader />
        </div>
      </div>
    )
  } else {
    icon = <div className='drop-icon' />
  }

  return (
    <Dropzone {...dropzoneProps()} className='dropfile' onDrop={onDrop} onDropRejected={onDropRejected}>
      {icon}
      <div className={className} />
    </Dropzone>
  )
}

export const dropzoneProps = () => {
  let commonProps = {activeClassName: 'active', rejectClassName: 'rejectedfile', multiple: false, accept: 'text/csv'}
  var isWindows = navigator.platform && navigator.platform.indexOf('Win') != -1
  if (isWindows) {
    commonProps = {
      ...commonProps,
      accept: '.csv',
      rejectClassName: ''
    }
  }
  return commonProps
}

RespondentsDropzone.propTypes = {
  survey: PropTypes.object,
  uploading: PropTypes.bool,
  onDrop: PropTypes.func.isRequired,
  onDropRejected: PropTypes.func.isRequired
}
