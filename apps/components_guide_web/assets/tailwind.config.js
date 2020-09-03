module.exports = {
  purge: [
    '../**/*.ex',
    '../**/*.eex',
    '../**/*.html',
  ],
  future: {
    removeDeprecatedGapUtilities: true,
  },
  plugins: [require("@tailwindcss/ui")],
  theme: {
    extend: {
      colors: {
        current: "currentColor",
      },
    },
  },
};
