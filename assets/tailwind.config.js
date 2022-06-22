// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

module.exports = {
  content: [
    './assets/js/**/*.js',
    './lib/components_guide_web.ex',
    './lib/components_guide_web/**/*.{ex,heex,eex,md}',
  ],
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography')
  ],
  theme: {
    extend: {
      colors: {
        current: 'currentColor',
      },
      zIndex: {
        'menu': 'var(--z-menu)'
      }
    },
  },
};
