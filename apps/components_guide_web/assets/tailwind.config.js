const colors = require('tailwindcss/colors');

module.exports = {
  mode: 'jit',
  purge: ['../lib/**/*.{ex,eex,html,md}'],
  plugins: [require('@tailwindcss/forms')],
  theme: {
    extend: {
      teal: colors.teal,
      colors: {
        teal: colors.teal,
        cyan: colors.cyan,
        orange: colors.orange,
        current: 'currentColor',
      },
      zIndex: {
        'menu': 'var(--z-menu)'
      }
    },
  },
};
