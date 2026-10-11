# AutoLinky-Production

The public React frontend is in [frontend](frontend/README.md). Run `npm ci` and `npm run build` there, then serve `frontend/dist/` on the VPS. It pre-renders English and Arabic pages for `https://auto-linky.com`. The server must provide `/download`; `/api/latest` supplies optional release details. Keep private environment variables in the server process.
