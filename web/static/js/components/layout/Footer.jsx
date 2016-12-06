import React from 'react'
import { config } from '../../config'

export default () => (
  <footer>
    <div className='row'>
      <div className='col s12'>
        InSTEDD ©
        <span className='right grey-text lighten2'>Version: {config.version}</span>
      </div>
    </div>
  </footer>
)
