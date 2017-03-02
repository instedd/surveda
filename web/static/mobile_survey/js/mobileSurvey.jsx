import React from 'react'
import ReactDOM from 'react-dom'
// import { render } from 'react-dom'
// // import { browserHistory } from 'react-router'
// // import { syncHistoryWithStore } from 'react-router-redux'
import Step from './components/Step'
// // import configureStore from './store/configureStore'

// // const store = configureStore()
// // const history = syncHistoryWithStore(browserHistory, store)

// const root = document.getElementById('root')
// if (root) {
//   render(<div> TEST</div>, root)
// }

console.log('Inside MobileSurvey.jsx')

ReactDOM.render(
  <div>
    <h1>RENDERING FROM THE JSX!</h1>
    <Step />
  </div>,
  document.getElementById('root')
)
