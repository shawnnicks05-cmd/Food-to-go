# Supabase data setup

1. Open the Supabase project's SQL Editor and run `schema.sql`.
   This creates `public.food_items` and the other tables, adds editable
   storefront contact fields, and creates the food and profile image buckets.
   The script can be rerun to apply these additions to an existing project. If
   the app still reports a missing table after the script
   completes, run `NOTIFY pgrst, 'reload schema';` in the SQL Editor and wait
   briefly for the API schema cache to refresh.
2. Add at least one stall directly in Supabase Table Editor. Admins can then
   approve accounts and assign stalls in the app. Food Stall accounts can add
   menu items from their dashboard.
3. Configure the `allow_usjr_email` auth hook with
   `allow_usjr_email.sql` if the project uses that hook.
4. Create an admin account by first registering it normally, then mark the
   account as admin from the SQL Editor using the query below. Replace the
   email with the actual admin account:

   ```sql
   update auth.users
   set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb)
     || '{"account_type":"admin"}'::jsonb
   where lower(email) = lower('admin@example.com')
   returning id, email, raw_app_meta_data;
   ```

   Sign out and sign back in after changing roles. Admins can then approve
   pending Food Stall accounts and assign a storefront in the app.
5. To run locally, use VS Code as usual. The existing project's Supabase URL
   and publishable key are configured as defaults. To override them for
   another project, supply them at build/run time:

   ```powershell
   flutter run -d windows `
     --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co `
     --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
   ```

## Deploying the web app to Netlify

The repository-root `netlify.toml` configures the Flutter project directory,
web build, and SPA fallback. Push the repository to GitHub and import it in
Netlify; Netlify reads this configuration and publishes `food_to_go/build/web`.
The build script installs Flutter 3.44.1 if it is not already available.

Optionally add `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` in Netlify's
environment variables to override the defaults. These are client-side values;
never add a Supabase service-role/secret key to a Flutter web build.

In Supabase Authentication URL Configuration, set the Site URL to the
deployed Netlify URL and add that site's redirect URL, for example
`https://YOUR-SITE.netlify.app/**`, to the allowed Redirect URLs. Web signups
now send confirmation links back to the current site instead of localhost.

The app loads catalog data and stores favorites, likes, and orders in
Supabase. The cart remains a temporary in-memory draft until checkout. Order
prices are recalculated from the current menu in the database when an order is
placed. Interface text, visual styling, and application behavior remain code
configuration rather than database records.

The SQL script also creates the public `food-images` Storage bucket. Stall
owners can choose an image from the Add/Edit Menu Item form; it is uploaded
under that stall's folder, then the returned public URL is saved in the menu
row when the form is saved. Images must be JPG, PNG, WebP, or GIF and at most
5 MB. Storage upload policies require the user's approved `app_metadata`
storefront assignment.

Regular users and approved Food Stall owners can open **My Profile** from
their dashboard to edit their name, phone number, and profile photo. Profile
details are saved in the signed-in user's Supabase Auth metadata. Food Stall
owners can additionally edit their assigned storefront's name, description,
business phone, and contact email; the storefront assignment itself remains
administrator-managed. Profile photos are stored in the public `profile-images`
bucket, with uploads restricted to each authenticated user's own folder.
