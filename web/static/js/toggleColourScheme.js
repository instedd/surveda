export const toggleColourScheme = (scheme) => {
  switch (scheme) {
    case 'better_data_for_health':
      document.documentElement.style.setProperty('--header-background-color', '#6648A2')
      document.documentElement.style.setProperty('--tabs-indicator-color', '#FBA400')
      document.documentElement.style.setProperty('--header-text-color', 'rgba(255, 255, 255, .33')
      break
    case 'default':
      document.documentElement.style.setProperty('--header-background-color', '#424242')
      document.documentElement.style.setProperty('--tabs-indicator-color', '#4CAF50')
      document.documentElement.style.setProperty('--header-text-color', '#9e9e9e')
      break
    default:
      throw new Error(`unknown scheme`)
  }
}
