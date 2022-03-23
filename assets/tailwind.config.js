const colors = require('tailwindcss/colors');

module.exports = {
  plugins: [require('@tailwindcss/forms')],
  theme: {
    extend: {
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
