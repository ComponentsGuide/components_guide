module.exports = {
  mode: 'jit',
  purge: ['../lib/**/*.{ex,eex,html,md}'],
  plugins: [require('@tailwindcss/forms')],
  theme: {
    extend: {
      colors: {
        current: 'currentColor',
      },
    },
  },
};
