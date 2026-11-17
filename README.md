# Shelf

A reading log built as an iPhone web app. Sign in, log each book you finish with a rating and notes, and see your books on any device.

- Plain HTML, CSS and JavaScript: no build step
- Logins and storage by [Supabase](https://supabase.com); each account can only read its own books (row-level security)
- Book covers are looked up by title and author from [Open Library](https://openlibrary.org)
- Yearly reading goal saved to your account
- Add to Home Screen on iPhone for a full-screen app

## Files

| File | What it is |
| --- | --- |
| `index.html` | The whole app |
| `config.js` | Supabase project URL and publishable key (safe to be public) |
| `schema.sql` | Database table and security rules; run once in Supabase's SQL Editor |
| `manifest.json`, `icon-*.png`, `icon.svg` | Home Screen name and icons |

## Run locally

```bash
python3 -m http.server 8123
```

Then open http://localhost:8123.

## Set up your own copy

1. Create a Supabase project and run `schema.sql` in its SQL Editor.
2. Put your project URL and publishable (anon) key in `config.js`. Never use the `service_role` / secret key.
3. Host the folder anywhere static: GitHub Pages, Netlify or similar.
4. In Supabase → Authentication → URL Configuration, set **Site URL** to your hosted address so confirmation emails link back to the app.
