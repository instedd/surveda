import { combineReducers }  from 'redux';
import { routerReducer as routing } from 'react-router-redux';
import projects from './projects';
import surveys from './surveys';
import questionnaires from './questionnaires';

export default combineReducers({
  routing,
  projects,
  surveys,
  questionnaires
});
