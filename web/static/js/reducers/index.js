import { combineReducers }  from 'redux'
import { routerReducer as routing } from 'react-router-redux'
import projects from './projects';

export default combineReducers({
  routing,
  projects
});
