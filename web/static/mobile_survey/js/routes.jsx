import React from 'react'
import { Route } from 'react-router'
import Step from './components/Step'

export default (
  <Route path='/mobile_survey/:respondentId' component={Step} />
)
