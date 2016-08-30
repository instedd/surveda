import React from 'react'
import { Link } from 'react-router'
import {Toolbar, ToolbarGroup, ToolbarSeparator, ToolbarTitle} from 'material-ui/Toolbar'

export default () => (
  <div style={{ marginTop: '50px'}}>
    <Toolbar>
      <ToolbarGroup>
        <Link to='/projects'>projects</Link>
      </ToolbarGroup>
    </Toolbar>
  </div>
)
