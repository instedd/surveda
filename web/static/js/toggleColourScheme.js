export const toggleColourScheme = (scheme) => {
  switch (scheme) {
    case 'better_data_for_health':
      document.documentElement.style.setProperty('--header-color', '#6648A2')
      break
    case 'default':
      document.documentElement.style.setProperty('--header-color', '#424242')
      break
    default:
      throw new Error(`unknown scheme`)
  }
}
