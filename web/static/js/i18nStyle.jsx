import React, { Component } from 'react'
import { translate } from 'react-i18next'

type Props = {
  t: Function
}

class I18nStyle extends Component<Props> {
  render() {
    const {t} = this.props
    return <style type='text/css'>
      {
`
.dropfile .drop-text.csv:before {
  content: '${t('Drop your CSV file here, or click to browse')}';
}
.dropfile .drop-text.csv.uploading:before {
  content: '${t('Uploading...')}';
}
.dropfile .drop-text.audio:before {
  content: '${t('Drop your MP3 or WAV file here, or click to browse')}';
}
.dropfile.active .drop-text:before {
  content: '${t('Drop your file to start uploading')}';
}
.dropfile.rejectedfile .drop-text:before {
  content: '${t('Invalid file type')}';
}
.audio-section .drop-uploading:before {
  content: '${t('Uploading...')}';
}
`
      }
    </style>
  }
}

export default translate()(I18nStyle)
