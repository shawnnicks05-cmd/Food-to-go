# Supabase data setup

1. Open the Supabase project's SQL Editor and run `schema.sql`.
2. In Table Editor, import `food_stalls.csv` into `food_stalls`, then import
   `food_items.csv` into `food_items`. Keep the CSV headers enabled.
3. Configure the `allow_usjr_email` auth hook with
   `allow_usjr_email.sql` if the project uses that hook.
4. Set an approved food-stall user's `app_metadata` to include
   `{"account_type":"foodstall","storefront_id":"<stall id>"}`. Regular users
   should have `{"account_type":"regular"}`. Use trusted admin tooling to edit
   `app_metadata`; never let users set these approval fields themselves.
5. Run the app in VS Code as usual. The existing project's Supabase URL and
   publishable key are configured as defaults. To override them for another
   project, supply them at build/run time:

   ```powershell
   flutter run -d windows `
     --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co `
     --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
   ```

The app loads catalog data and stores favorites, likes, and orders in
Supabase. The cart remains a temporary in-memory draft until checkout. Order
prices are recalculated from the current menu in the database when an order is
placed. Interface text, visual styling, and application behavior remain code
configuration rather than database records.

The CSVs preserve the current external image URLs. If you upload images to
Supabase Storage, replace the corresponding `image_url` values with their
public Storage URLs before or after importing the rows.

The SQL script also creates the public `food-images` Storage bucket. Stall
owners can choose an image from the Add/Edit Menu Item form; it is uploaded
under that stall's folder, then the returned public URL is saved in the menu
row when the form is saved. Images must be JPG, PNG, WebP, or GIF and at most
5 MB. Storage upload policies require the user's approved `app_metadata`
storefront assignment.
