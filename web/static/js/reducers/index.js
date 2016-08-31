import { combineReducers }  from 'redux';
import { routerReducer as routing } from 'react-router-redux';
import projects from './projects';
import surveys from './surveys';

export default combineReducers({
  routing,
  projects,
  surveys
});
