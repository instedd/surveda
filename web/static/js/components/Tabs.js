import React from 'react'

export const Tabs = ({children}) => (
  <ul className="tabs" ref={node => $(node).tabs()}>
    {children}
  </ul>
)
