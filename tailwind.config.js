/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/frontend/src/index.html",
    "./src/frontend/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'bg-primary': '#242424',
        'btn-primary': '#1a1a1a'
      },
    },
  },
  plugins: [],
}
