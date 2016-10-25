import React from 'react'
import { config } from '../../config'

export default () => (
  <footer>
    <div className='row'>
      <div className='col s12'>
        © 2016 InSTEDD
        <span className='right'>Version: {config.version}</span>
      </div>
    </div>
  </footer>
)
