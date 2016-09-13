import React from 'react'
import { createDevTools } from 'redux-devtools'
import ChartMonitor from 'redux-devtools-chart-monitor'
import DockMonitor from 'redux-devtools-dock-monitor'
import LogMonitor from 'redux-devtools-log-monitor'
import SliderMonitor from 'redux-slider-monitor'

export default createDevTools(
  <DockMonitor toggleVisibilityKey="ctrl-h"
               changePositionKey="ctrl-w"
               changeMonitorKey='ctrl-m'
               defaultIsVisible={false}>
    <LogMonitor />
    <SliderMonitor />
    <ChartMonitor />
  </DockMonitor>
)
