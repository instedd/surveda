// @flow

type ProviderConfig = {
  friendlyName: string,
  baseUrl: string,
  channel_ui: boolean,
}

type Config = {
  nuntium: ProviderConfig[],
  verboice: ProviderConfig[],
  available_languages_for_numbers: string[],
  custom_language_names: {[string]: string},
}

const defaultConfig = {
  available_languages_for_numbers: ["en"],
  custom_language_names: {},
  user_settings: {
    language: "en",
  },
  nuntium: [],
  verboice: [],
}

export const config: Config = window.appConfig || defaultConfig
