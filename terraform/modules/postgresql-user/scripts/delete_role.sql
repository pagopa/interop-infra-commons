DO $$
BEGIN
  IF EXISTS (
    SELECT FROM pg_catalog.pg_roles WHERE rolname = '${USERNAME}'
  ) THEN
    DROP ROLE ${USERNAME};
  END IF;
END
$$;
