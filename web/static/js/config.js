// @flow

type ProviderConfig = {
  friendlyName: string,
  baseUrl: string
}

type Config = {
  nuntium: ProviderConfig[],
  verboice: ProviderConfig[],
  available_languages_for_numbers: string[]
};

const defaultConfig = {
  user_settings: {
    language: 'en'
  }
}

export const config: Config = window.appConfig || defaultConfig
