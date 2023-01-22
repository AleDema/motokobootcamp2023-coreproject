/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./frontend/**/*.{js,jsx,ts,tsx}",
    "./index.html"
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
