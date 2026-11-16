create or replace function public.allow_usjr_email(event jsonb)
returns jsonb
language plpgsql
as $$
declare
  user_email text := lower(coalesce(event->'user'->>'email', ''));
  requested_type text :=
    coalesce(event->'user'->'user_metadata'->>'requested_account_type', 'regular');
begin
  if requested_type = 'foodstall' then
    return '{}'::jsonb;
  end if;

  if right(user_email, length('@usjr.edu.ph')) <> '@usjr.edu.ph' then
    return jsonb_build_object(
      'error',
      jsonb_build_object(
        'http_code', 403,
        'message', 'Regular accounts must use a USJ-R email address.'
      )
    );
  end if;

  return '{}'::jsonb;
end;
$$;

grant usage on schema public to supabase_auth_admin;
grant execute on function public.allow_usjr_email(jsonb) to supabase_auth_admin;
revoke execute on function public.allow_usjr_email(jsonb)
  from authenticated, anon, public;
