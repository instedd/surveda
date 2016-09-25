export const GUISSO_TOKEN = 'GUISSO_TOKEN';

export const obtainToken = (guissoSession) => {
  return (dispatch, getState) => {
    const existingToken = getState().guisso[guissoSession.config.appId];
    if (existingToken) {
      return Promise.resolve(existingToken);
    }

    return guissoSession.authorize("token").then(token => {
      dispatch({
        type: GUISSO_TOKEN,
        app: guissoSession.config.appId,
        token
      });
      return token
    });
  }
}
