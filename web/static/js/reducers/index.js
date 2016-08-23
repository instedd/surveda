import { combineReducers }  from 'redux'
import { routerReducer as routing } from 'react-router-redux'
import studies from './studies';

export default combineReducers({
  routing,
  studies
});
