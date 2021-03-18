module.exports = {
  purge: ["../**/*.ex", "../**/*.eex", "../**/*.html", "../**/*.md"],
  plugins: [require("@tailwindcss/forms")],
  theme: {
    extend: {
      colors: {
        current: "currentColor",
      },
    },
  },
};
