import { getLocaleFromNavigator, init } from 'svelte-intl-precompile'
// @ts-ignore
import { registerAll } from '$locales'
registerAll()
init({ initialLocale: 'ca', fallbackLocale: 'ca' })
