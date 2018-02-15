import React from 'react'
import { config } from '../../config'
import LanguageSelector from './LanguageSelector'

export default () => (
  <footer>
    <div className='row'>
      <div className='col s12'>
        InSTEDD ©
        <span className='right'>
          <span className='left'>
            <LanguageSelector />
          </span>
          <span className='right grey-text lighten2'>Version: {config.version}</span>
        </span>
      </div>
    </div>
  </footer>
)
