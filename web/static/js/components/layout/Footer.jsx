import React from 'react'
import { config } from '../../config'
import LanguageSelector from './LanguageSelector'

export default () => (
  <footer>
    <div className='row'>
      <div className='col s12 m2'>
        InSTEDD ©
      </div>
      <div className='col s12 m10 right-align'>
        <LanguageSelector className='languageSelector' />
        <span className='grey-text lighten2'>Version: {config.version}</span>
      </div>
    </div>
  </footer>
)
